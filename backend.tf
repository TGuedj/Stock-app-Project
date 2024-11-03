resource "aws_s3_bucket" "tf_state&stocksite_images" {
  bucket = "tf-state-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}
