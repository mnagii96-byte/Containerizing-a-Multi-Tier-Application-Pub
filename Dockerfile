# ---- Build stage: compile the VProfile WAR ----
FROM maven:3.9-eclipse-temurin-11 AS build
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch main https://github.com/hkhcoder/vprofile-project.git .
RUN mvn -q install -DskipTests

# ---- Run stage: Tomcat 9 on Java 11 ----
FROM tomcat:9-jdk11-temurin
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /src/target/vprofile-*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
