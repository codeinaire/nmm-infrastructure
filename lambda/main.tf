resource "aws_iam_role" "nmm_app" {
  name               = var.policy_role_name
  assume_role_policy = data.aws_iam_policy_document.nmm_app.json
}

resource "aws_iam_role_policy_attachment" "nmm_app" {
  role       = aws_iam_role.nmm_app.name
  policy_arn = aws_iam_policy.nmm_app.arn
}

resource "aws_iam_policy" "nmm_app" {
  name   = var.policy_role_name
  path   = "/"
  policy = "${data.aws_iam_policy_document.nmm_app.json}"
}

data "aws_iam_policy_document" "nmm_app" {
  version = "2012-10-17"

  statement {
    sid = "AccessCloudwatchLogs"
    actions = ["logs:*"]
    effect = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  # Change this to dynamic block by passing an object through
  statement {
    sid = "PetsS3Write"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [var.resource_arn]
  }
}

data "archive_file" "nmm_app" {
  type = "zip"
  source_dir = "./apollo-sequelize-terra-test"
  output_path = "apolloSeqTerraTest.zip"
}

resource "aws_lambda_function" "nmm_app" {
  filename = "${data.archive_file.nmm_app.output_path}"
  function_name = var.function_name
  role = aws_iam_role.nmm_app.arn
  handler = "./src/index.graphqlHandler"
  runtime = "nodejs10.x"
  source_code_hash = "${filebase64sha256("${data.archive_file.nmm_app.output_path}")}"
  publish = true
  layers = [aws_lambda_layer_version.lambda_node_modules.arn]
}

data "archive_file" "node_modules" {
  type        = "zip"
  source_dir  = "./node_modules"
  output_path = "node_modules.zip"
}

resource "aws_lambda_layer_version" "lambda_node_modules" {
  filename   = "node_modules.zip"
  layer_name = "node_modules"

  compatible_runtimes = ["nodejs10.x"]

  depends_on = ["data.archive_file.node_modules"]
}