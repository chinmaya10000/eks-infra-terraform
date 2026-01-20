module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.14.0"

  name               = local.eks_cluster_name
  kubernetes_version = local.eks_version

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Create just the IAM resources for EKS Auto Mode for use with custom node pools
#   create_auto_mode_iam_resources = true
#   compute_config = {
#     enabled = true
#   }

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 10
      desired_size = 3
    }
  }

  create_kms_key                  = true
  kms_key_description             = "KMS key for EKS cluster ${local.eks_cluster_name}"
  kms_key_deletion_window_in_days = 7

  tags = {
    Name = "${local.env}-${local.eks_cluster_name}"
  }

  depends_on = [ module.vpc ]
}
