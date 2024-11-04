output "public_subnet_ids" {
    value = aws_subnet.artbdc_pub_subnets[*].id
}