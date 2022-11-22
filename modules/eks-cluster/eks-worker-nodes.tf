resource "aws_iam_role" "eks-node" {
  # count = var.assume_role_policy == null ? 0 : 1
  name = "${var.Environment}-eks-node-group-nodes"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
# depends_on = [
#     aws_eks_node_group.private-node-group
#   ]
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node.name
}

resource "aws_eks_node_group" "private-node-group" {
  cluster_name    = aws_eks_cluster.dbs-eks-cluster.name
  node_group_name = "${var.Environment}-${var.name}-private-nodes"
  node_role_arn   = aws_iam_role.eks-node.arn
  subnet_ids = [
    aws_subnet.priv-subnet-1.id,
    aws_subnet.priv-subnet-2.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = var.instance-types

  scaling_config {
    desired_size = var.desired-size
    max_size     = var.max-size
    min_size     = var.min-size
  }

  update_config {
    max_unavailable = var.max-unavailable
  }

  labels = {
    "role" = "general"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-node-AmazonEC2ContainerRegistryReadOnly,
  ]

}
