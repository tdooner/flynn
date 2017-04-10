resource "aws_iam_user" "flynn-blobstore" {
  name = "${var.cluster_name_prefix}flynn-blobstore"
  path = "/"
}

resource "aws_iam_policy_attachment" "flynn-blobstore" {
  name = "${var.cluster_name_prefix}flynn-blobstore"
  users = ["${aws_iam_user.flynn-blobstore.name}"]
  policy_arn = "${aws_iam_policy.flynn-blobstore.arn}"
}

resource "aws_iam_access_key" "flynn-blobstore" {
  user = "${aws_iam_user.flynn-blobstore.name}"
}

resource "aws_s3_bucket" "flynn-blobstore" {
  bucket = "${var.cluster_name_prefix}flynn-blobstore-tdooner"
  acl = "private"
}

resource "aws_iam_policy" "flynn-blobstore" {
  name = "${var.cluster_name_prefix}flynn-blobstore"
  path = "/"
  description = "User to upload ${var.cluster_name_prefix}flynn blob artifacts"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.flynn-blobstore.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.flynn-blobstore.bucket}/*"
      ]
    }
  ]
}
EOF
}

output "blobstore_bucket" {
  value = "${aws_s3_bucket.flynn-blobstore.bucket}"
}

output "blobstore_access_key_id" {
  value = "${aws_iam_access_key.flynn-blobstore.id}"
}

output "blobstore_secret_access_key" {
  value = "${aws_iam_access_key.flynn-blobstore.secret}"
}
