# Dash demo: Training Peaks data

A Dash application to just make a few plots using my training data.
Made as a simple app to demonstrate deploying Dash apps using Docker on
AWS's Elastic Container Service (ECS).

## Local development

1. Create a Python venv with a >=3.6 interpreter.

2. Activate venv (`source <venv path>/bin/activate`).

3. Install Python dependencies using `pip install -r requirements.txt`.

4. Run the server using `python wsgi.py`.

## Running locally

To run a local instance, the easiest way is to build the Docker image:

1. Build the image using `docker build -t tp_dashboard .`.

2. Run the image using `docker run -p 80:8080 etp_dashboard:latest`.

3. Use your browser to navigate to `127.0.0.1:8080` to view the application.

## Deploying onto AWS FARGATE

When making changes, you need to rebuild the Docker image and push it to AWS
ECR, then re-deploy.

1. Run `$(aws ecr get-login --no-include-email --region <your AWS region>.)`
   to authenticate your shell.

2. Build the image using `docker build -t tp_dashboard .`.

3. Tag the image using `docker tag tp_dashboard:latest <your account id>.dkr.ecr.<your AWS region>.amazonaws.com/tp_dashboard:latest`.

4. Push the image to AWS ECR using `docker push <your account id>.dkr.ecr.<your AWS region>.amazonaws.com/tp_dashboard:latest`.

5. Create a new FARGATE instance or update the running FARGATE instance
   with the Update button at the Training Peaks Dash ECS page.

---

When deploying onto a new server, 1 vCPU and 2GB memory are the absolute
minimum necessary for decent operation.

---

I made a bash script caled `commands_AWS_deploy.sh` that uses the CLI to deploy the cluster.
