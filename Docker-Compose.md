# Flask URL Shortener with MySQL (Dockerized)

This is a simple **URL Shortener** built using **Flask** and **MySQL**. It allows users to shorten long URLs and retrieve the original URLs using a unique short code.

## **Features**
- Shorten long URLs into a compact format
- Store and retrieve URLs using MySQL
- Use **Docker Compose** to run both Flask and MySQL containers seamlessly

---

## **Prerequisites**
Ensure you have the following installed on your system:
- **Docker**: [Download and install Docker](https://www.docker.com/get-started)
- **Docker Compose**: Typically included with Docker Desktop

---

## **How to Run the Application using Docker**

### **Step 1: Clone the Repository**
```sh
git clone -b <branch_name> <repository_url>
cd <repository_url>
```

### **Step 2: Configure Environment Variables**
Modify the .env file with your MySQL credentials:
```sh
MYSQL_HOST=mysql-container
MYSQL_USER=root
MYSQL_PASSWORD="<mysql password>"
MYSQL_DATABASE=url_shortener
```
Docker containers communicate via container names, so we use mysql-container instead of localhost.
For docker, the host is set to 'mysql-container' which is the name of the MySQL container.
For local development, you can set it to 'localhost' or the appropriate host for your MySQL server.

### **Step 3: Build the Docker Image**
```sh
docker build -t flask-url-shortener .
```
Uses the Dockerfile to create an image for Flask application.
Installs dependencies from requirements.txt.
Exposes Flask on port 5000.

### **Step 4: Start the MySQL Container**
```sh
docker run --name mysql-container -e MYSQL_ROOT_PASSWORD="<mysql password>" -e MYSQL_DATABASE=url_shortener -p 3307:3306 -d mysql:latest
```
Creates a MySQL docker container named mysql-container.
Sets the root password.
Automatically creates a database url_shortener.
Runs MySQL in the background (-d).

### **Step 5: Run Database Migration**
```sh
docker exec -i mysql-container mysql -u root -p "<mysql password>" url_shortener < url_shortener_db.sql
```
Executes the url_shortener_db.sql file to create the necessary database table

### **Step 6: Run the Flask Application**
```sh
docker run --name url-shortener-container --link mysql-container -p 5000:5000 -d flask-url-shortener
```
Runs the Flask app in a container.
Links it to mysql-container to enable database access.
Maps port 5000 of the container to 5000 on your machine.

### **Step 7: Verify Running Containers**
Check if both containers are running:
```sh
docker ps
```

### **Step 8: Access the Application**
Open your browser and go to:
```sh
http://localhost:5000
```
You should see the homepage where you can enter a long URL to shorten.

---

## **How to Run the Application using Docker Compose**
Follow till Step 2

### **Step 3: Build and Start Containers**
```sh
docker-compose up --build
```
This single command will:
- Build the Flask application image
- Start MySQL and Flask containers
- Set up the database
- Start the application

(Ensure that the database tables have been created.)

### **Step 4: Access the Application**
Open your browser and go to:
```sh
http://localhost:5000
```
You should see the homepage where you can enter a long URL to shorten.

---

## **Stopping and Removing Containers**
If you need to stop and remove the containers:
```sh
docker stop url-shortener-container mysql-container
docker rm url-shortener-container mysql-container
```

To remove the Docker image:
```sh
docker rmi flask-url-shortener
```

-- OR --

If using Docker Compose:
Stop the containers using:
```sh
docker-compose down
```

Stop and Remove Volumes:
```sh
docker-compose down -v
```
