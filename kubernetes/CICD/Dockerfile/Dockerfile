FROM java:openjdk-8-jre-alpine
ARG port
ENV port=${port}
COPY yunfeigj-devops-1.0-SNAPSHOT.jar /apps/
WORKDIR /apps
EXPOSE ${port}
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","yunfeigj-devops-1.0-SNAPSHOT.jar"]