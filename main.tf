variable "namespace" {
  default = "cloudtech"
}

variable "stage" {
  default = "dev"
}

module "courses_label" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = var.namespace
  stage     = var.stage
  name      = "courses"
}

resource "aws_dynamodb_table" "courses" {
  name         = module.courses_label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

module "authors_label" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = var.namespace
  stage     = var.stage
  name      = "authors"
}

resource "aws_dynamodb_table" "authors" {
  name         = module.authors_label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_roles" {
  for_each = toset([
    "delete-course",
    "get-all-authors",
    "get-all-courses",
    "get-course",
    "put-course"
  ])

  name               = "cloudtech-dev-${each.value}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
# 1. Get All Authors
data "archive_file" "get_all_authors_zip" {
  type        = "zip"
  source_file = "${path.module}/src/get-all-authors.js"
  output_path = "${path.module}/get-all-authors.zip"
}
resource "aws_lambda_function" "get_all_authors" {
  filename         = data.archive_file.get_all_authors_zip.output_path
  function_name    = "${var.namespace}-${var.stage}-get-all-authors"
  role             = aws_iam_role.lambda_roles["get-all-authors"].arn
  handler          = "get-all-authors.handler"
  source_code_hash = data.archive_file.get_all_authors_zip.output_base64sha256
  runtime          = "nodejs18.x"
}

# 2. Get All Courses
data "archive_file" "get_all_courses_zip" {
  type        = "zip"
  source_file = "${path.module}/src/get-all-courses.js"
  output_path = "${path.module}/get-all-courses.zip"
}
resource "aws_lambda_function" "get_all_courses" {
  filename         = data.archive_file.get_all_courses_zip.output_path
  function_name    = "${var.namespace}-${var.stage}-get-all-courses"
  role             = aws_iam_role.lambda_roles["get-all-courses"].arn
  handler          = "get-all-courses.handler"
  source_code_hash = data.archive_file.get_all_courses_zip.output_base64sha256
  runtime          = "nodejs18.x"
}

# 3. Get Course
data "archive_file" "get_course_zip" {
  type        = "zip"
  source_file = "${path.module}/src/get-course.js"
  output_path = "${path.module}/get-course.zip"
}
resource "aws_lambda_function" "get_course" {
  filename         = data.archive_file.get_course_zip.output_path
  function_name    = "${var.namespace}-${var.stage}-get-course"
  role             = aws_iam_role.lambda_roles["get-course"].arn
  handler          = "get-course.handler"
  source_code_hash = data.archive_file.get_course_zip.output_base64sha256
  runtime          = "nodejs18.x"
}

# 4. Save Course
data "archive_file" "save_course_zip" {
  type        = "zip"
  source_file = "${path.module}/src/save-course.js"
  output_path = "${path.module}/save-course.zip"
}
resource "aws_lambda_function" "save_course" {
  filename         = data.archive_file.save_course_zip.output_path
  function_name    = "${var.namespace}-${var.stage}-save-course"
  role             = aws_iam_role.lambda_roles["put-course"].arn
  handler          = "save-course.handler"
  source_code_hash = data.archive_file.save_course_zip.output_base64sha256
  runtime          = "nodejs18.x"
}

# 5. Update Course
data "archive_file" "update_course_zip" {
  type        = "zip"
  source_file = "${path.module}/src/update-course.js"
  output_path = "${path.module}/update-course.zip"
}
resource "aws_lambda_function" "update_course" {
  filename         = data.archive_file.update_course_zip.output_path
  function_name    = "${var.namespace}-${var.stage}-update-course"
  role             = aws_iam_role.lambda_roles["put-course"].arn
  handler          = "update-course.handler"
  source_code_hash = data.archive_file.update_course_zip.output_base64sha256
  runtime          = "nodejs18.x"
}

# 6. Delete Course
data "archive_file" "delete_course_zip" {
  type        = "zip"
  source_file = "${path.module}/src/delete-course.js"
  output_path = "${path.module}/delete-course.zip"
}
resource "aws_lambda_function" "delete_course" {
  filename         = data.archive_file.delete_course_zip.output_path
  function_name    = "${var.namespace}-${var.stage}-delete-course"
  role             = aws_iam_role.lambda_roles["delete-course"].arn
  handler          = "delete-course.handler"
  source_code_hash = data.archive_file.delete_course_zip.output_base64sha256
  runtime          = "nodejs18.x"
}
