#! /bin/bash
yum update -y
yum install python3 -y
pip3 install flask
pip3 install flask_mysql
echo ${rds_endpoint} >> /home/ec2-user/dbserver.endpoint
TOKEN="---------------------------"
FOLDER="https://$TOKEN@raw.githubusercontent.com/EmirhanImranTuzel/phonebook_app/master"
curl -s --create-dirs -o "/home/ec2-user/templates/index.html" -L "$FOLDER"/templates/index.html
curl -s --create-dirs -o "/home/ec2-user/templates/add-update.html" -L "$FOLDER"/templates/add-update.html
curl -s --create-dirs -o "/home/ec2-user/templates/delete.html" -L "$FOLDER"/templates/delete.html
curl -s --create-dirs -o "/home/ec2-user/phonebook-app.py" -L "$FOLDER"/phonebook-app.py
python3 /home/ec2-user/phonebook-app.py
