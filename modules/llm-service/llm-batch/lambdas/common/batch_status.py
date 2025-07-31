"""
バッチ処理の状態管理モジュール

LLMバッチジョブの状態遷移を安全に管理するBatch Statusを実装します。
不正な状態遷移を防ぎ、一貫した状態管理を提供します。
"""

from dataclasses import dataclass
from datetime import datetime, timezone
from enum import Enum
from typing import Dict, List, Optional


class BatchStatus(Enum):
    """バッチジョブの状態定義"""
    QUEUED = "queued"           # キューに登録済み
    PROCESSING = "processing"   # 処理中
    COMPLETED = "completed"     # 正常完了
    FAILED = "failed"          # 失敗
    CANCELLED = "cancelled"    # キャンセル済み
    RETRYING = "retrying"      # リトライ中


class ErrorType(Enum):
    """エラータイプの分類"""
    RETRIABLE = "retriable"         # リトライ可能なエラー
    PERMANENT = "permanent"         # 恒久的なエラー
    RATE_LIMIT = "rate_limit"       # レート制限
    VALIDATION = "validation"       # バリデーションエラー
    AUTHENTICATION = "authentication"  # 認証エラー


@dataclass
class StateTransition:
    """状態遷移の記録"""
    from_status: BatchStatus
    to_status: BatchStatus
    timestamp: datetime
    reason: Optional[str] = None
    additional_data: Optional[Dict] = None


@dataclass 
class ProcessingError:
    """処理エラーの詳細情報"""
    error_type: ErrorType
    message: str
    retry_after: Optional[int] = None  # リトライまでの秒数
    retry_count: int = 0
    max_retries: int = 3


class BatchStateManager:
    """バッチジョブの状態管理クラス"""
    
    # 許可された状態遷移の定義
    VALID_TRANSITIONS: Dict[BatchStatus, List[BatchStatus]] = {
        BatchStatus.QUEUED: [
            BatchStatus.PROCESSING,
            BatchStatus.CANCELLED,
            BatchStatus.FAILED
        ],
        BatchStatus.PROCESSING: [
            BatchStatus.COMPLETED,
            BatchStatus.FAILED,
            BatchStatus.RETRYING,
            BatchStatus.CANCELLED
        ],
        BatchStatus.RETRYING: [
            BatchStatus.PROCESSING,
            BatchStatus.FAILED,
            BatchStatus.CANCELLED
        ],
        BatchStatus.FAILED: [
            BatchStatus.RETRYING,
            BatchStatus.CANCELLED
        ],
        BatchStatus.COMPLETED: [],  # 完了状態からは遷移不可
        BatchStatus.CANCELLED: [],  # キャンセル状態からは遷移不可
    }
    
    # 最終状態（これ以上遷移しない状態）
    FINAL_STATES = {BatchStatus.COMPLETED, BatchStatus.CANCELLED}
    
    def __init__(self, initial_status: BatchStatus = BatchStatus.QUEUED):
        """
        状態管理クラスの初期化
        
        Args:
            initial_status: 初期状態
        """
        self.current_status = initial_status
        self.transitions: List[StateTransition] = []
        self.errors: List[ProcessingError] = []
        self.created_at = datetime.now(timezone.utc)
        self.updated_at = self.created_at
    
    def can_transition_to(self, new_status: BatchStatus) -> bool:
        """
        指定された状態への遷移が可能かチェック
        
        Args:
            new_status: 遷移先の状態
            
        Returns:
            bool: 遷移可能な場合True
        """
        if self.current_status in self.FINAL_STATES:
            return False
            
        allowed_statuses = self.VALID_TRANSITIONS.get(self.current_status, [])
        return new_status in allowed_statuses
    
    def transition_to(
        self, 
        new_status: BatchStatus, 
        reason: Optional[str] = None,
        additional_data: Optional[Dict] = None
    ) -> bool:
        """
        状態を遷移させる
        
        Args:
            new_status: 遷移先の状態
            reason: 遷移の理由
            additional_data: 追加データ
            
        Returns:
            bool: 遷移に成功した場合True
            
        Raises:
            ValueError: 不正な状態遷移の場合
        """
        if not self.can_transition_to(new_status):
            raise ValueError(
                f"Invalid state transition: {self.current_status.value} -> {new_status.value}"
            )
        
        # 遷移記録を保存
        transition = StateTransition(
            from_status=self.current_status,
            to_status=new_status,
            timestamp=datetime.now(timezone.utc),
            reason=reason,
            additional_data=additional_data
        )
        
        self.transitions.append(transition)
        self.current_status = new_status
        self.updated_at = transition.timestamp
        
        return True
    
    def add_error(self, error: ProcessingError) -> None:
        """
        エラー情報を追加
        
        Args:
            error: エラー詳細
        """
        self.errors.append(error)
    
    def get_retry_count(self) -> int:
        """現在のリトライ回数を取得"""
        retry_errors = [e for e in self.errors if e.error_type == ErrorType.RETRIABLE]
        return len(retry_errors)
    
    def should_retry(self) -> bool:
        """リトライすべきかどうかを判定"""
        if self.current_status != BatchStatus.FAILED:
            return False
            
        retry_count = self.get_retry_count()
        if not self.errors:
            return False
            
        latest_error = self.errors[-1]
        return (
            latest_error.error_type == ErrorType.RETRIABLE and
            retry_count < latest_error.max_retries
        )
    
    def get_next_retry_delay(self) -> Optional[int]:
        """次のリトライまでの遅延時間を取得（秒）"""
        if not self.should_retry():
            return None
            
        retry_count = self.get_retry_count()
        # 指数バックオフ: 2^retry_count * 60秒（最大30分）
        delay = min(2 ** retry_count * 60, 1800)
        return delay
    
    def is_final_state(self) -> bool:
        """現在の状態が最終状態かどうか"""
        return self.current_status in self.FINAL_STATES
    
    def get_duration(self) -> float:
        """処理開始から現在までの経過時間（秒）"""
        return (self.updated_at - self.created_at).total_seconds()
    
    def to_dict(self) -> Dict:
        """状態管理情報を辞書形式で取得"""
        return {
            "current_status": self.current_status.value,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "duration_seconds": self.get_duration(),
            "retry_count": self.get_retry_count(),
            "should_retry": self.should_retry(),
            "is_final": self.is_final_state(),
            "transitions": [
                {
                    "from": t.from_status.value,
                    "to": t.to_status.value,
                    "timestamp": t.timestamp.isoformat(),
                    "reason": t.reason,
                    "additional_data": t.additional_data
                }
                for t in self.transitions
            ],
            "errors": [
                {
                    "type": e.error_type.value,
                    "message": e.message,
                    "retry_after": e.retry_after,
                    "retry_count": e.retry_count,
                    "max_retries": e.max_retries
                }
                for e in self.errors
            ]
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'BatchStateManager':
        """辞書データから状態管理インスタンスを復元"""
        current_status = BatchStatus(data["current_status"])
        state_manager = cls(current_status)
        
        state_manager.created_at = datetime.fromisoformat(data["created_at"])
        state_manager.updated_at = datetime.fromisoformat(data["updated_at"])
        
        # 遷移履歴を復元
        for t_data in data.get("transitions", []):
            transition = StateTransition(
                from_status=BatchStatus(t_data["from"]),
                to_status=BatchStatus(t_data["to"]),
                timestamp=datetime.fromisoformat(t_data["timestamp"]),
                reason=t_data.get("reason"),
                additional_data=t_data.get("additional_data")
            )
            state_manager.transitions.append(transition)
        
        # エラー履歴を復元
        for e_data in data.get("errors", []):
            error = ProcessingError(
                error_type=ErrorType(e_data["type"]),
                message=e_data["message"],
                retry_after=e_data.get("retry_after"),
                retry_count=e_data.get("retry_count", 0),
                max_retries=e_data.get("max_retries", 3)
            )
            state_manager.errors.append(error)
        
        return state_manager


def classify_error(exception: Exception) -> ProcessingError:
    """
    例外をエラータイプに分類
    
    Args:
        exception: 発生した例外
        
    Returns:
        ProcessingError: 分類されたエラー情報
    """
    error_message = str(exception)
    
    # boto3のClientErrorの場合
    if hasattr(exception, 'response'):
        error_code = exception.response.get('Error', {}).get('Code', '')
        
        # レート制限エラー
        if error_code in ['ThrottlingException', 'TooManyRequestsException']:
            return ProcessingError(
                error_type=ErrorType.RATE_LIMIT,
                message=error_message,
                retry_after=60  # 1分後にリトライ
            )
        
        # リトライ可能なエラー
        if error_code in ['ServiceUnavailable', 'InternalServerError', 'RequestTimeout']:
            return ProcessingError(
                error_type=ErrorType.RETRIABLE,
                message=error_message
            )
        
        # 認証エラー
        if error_code in ['UnauthorizedOperation', 'InvalidUserID.NotFound', 'Forbidden']:
            return ProcessingError(
                error_type=ErrorType.AUTHENTICATION,
                message=error_message
            )
    
    # バリデーションエラー
    if isinstance(exception, (ValueError, KeyError)):
        return ProcessingError(
            error_type=ErrorType.VALIDATION,
            message=error_message
        )
    
    # その他は恒久的エラーとして扱う
    return ProcessingError(
        error_type=ErrorType.PERMANENT,
        message=error_message
    ) 