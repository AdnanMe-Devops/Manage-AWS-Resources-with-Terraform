Using Variables to Generalize Terraform Configuration

1. Delete the configuration changes you made in the last Lab Step:

sed -i '/.*web_subnet_1.*/,$d' main.tf
This deletes all the lines in the configuration file starting from the line that declares web_subnet_1.

 

2. Apply the configuration changes to realize the new desired state with the subnets and instance removed, and enter yes when prompted:


terraform apply

3. Create a variable file named variables.tf:


cat > variables.tf <<'EOF'
# Example of a string variable
variable network_cidr {
  default = "192.168.100.0/24"
}

# Example of a list variable
variable availability_zones {
  default = ["us-west-2a", "us-west-2b"]
}

# Example of an integer variable
variable instance_count {
  default = 2
}

# Example of a map variable
variable ami_ids {
  default = {
    "us-west-2" = "ami-0fb83677"
    "us-east-1" = "ami-97785bed"
  }
}

EOF
The default value for each variable is used unless overridden. You can use the validate command to check for any syntax errors when writing your own variable files.

 

4. Add the following configuration that uses the variables to dynamically create subnet and instance resources:


cat >> main.tf <<'EOF'
resource "aws_subnet" "web_subnet" {
  # Use the count meta-parameter to create multiple copies
  count             = 2
  vpc_id            = "${aws_vpc.web_vpc.id}"
  # cidrsubnet function splits a cidr block into subnets
  cidr_block        = "${cidrsubnet(var.network_cidr, 1, count.index)}"
  # element retrieves a list element at a given index
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags {
    Name = "Web Subnet ${count.index + 1}"
  }
}

resource "aws_instance" "web" {
  count         = "${var.instance_count}"
  # lookup returns a map value for a given key
  ami           = "${lookup(var.ami_ids, "us-west-2")}"
  instance_type = "t2.micro"
  # Use the subnet ids as an array and evenly distribute instances
  subnet_id     = "${element(aws_subnet.web_subnet.*.id, count.index % length(aws_subnet.web_subnet.*.id))}"
  
  tags {
    Name = "Web Server ${count.index + 1}"
  }
}

EOF
The count metaparameter allows us to create multiple copies of a resource. Interpolation using count.index allows you to modify the copies. index is zero for the first copy, one for the second, etc. For example, the instances are distributed between the two subnets that are created by using count.index to select between the subnets. 

 

5. Create an output variable file called outputs.tf that 

cat > outputs.tf <<'EOF'
output "ips" {
  # join all the instance private IPs with commas separating them
  value = "${join(", ", aws_instance.web.*.private_ip)}"
}
EOF
When  run apply, Terraform loads all files in the directory ending with .tf, so both input and output variable files are loaded.

 

6. View the execution plan by issuing the apply command:


terraform apply

 7. Enter yes at the prompt to apply the execution plan to create the resources.

 In the output will see the instances are created in different subnets:

8. Use the output command to retrieve the ips output value:

terraform output ips
Creating outputs is more convenient than sifting through all the state attributes, and can make integration with automation scripts easy.

 
