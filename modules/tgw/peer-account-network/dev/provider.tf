provider "aws" {
  region = local.region
  default_tags {
    tags = local.tags
  }
}

#####################################################################################
# Peer用プロバイダー
#####################################################################################

provider "aws" {
  region     = local.region
  alias      = "peer"
  access_key = var.PEER_ACCESS_KEY
  secret_key = var.PEER_SECRET_KEY
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region     = local.region
  alias      = "peer2"
  access_key = var.PEER2_ACCESS_KEY
  secret_key = var.PEER2_SECRET_KEY
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region     = local.region
  alias      = "peer3"
  access_key = var.PEER3_ACCESS_KEY
  secret_key = var.PEER3_SECRET_KEY
  default_tags {
    tags = local.tags
  }
}

terraform {
  cloud {
    organization = "sample-infra"
    workspaces {
      name = "sample-workspace"
    }
  }
}
