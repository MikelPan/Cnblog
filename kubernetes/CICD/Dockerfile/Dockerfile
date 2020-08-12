FROM java:openjdk-8-jre-alpine
ARG port
ARG jar_name
ENV port=${port}
COPY ${jar_name} /apps/
WORKDIR /apps
EXPOSE ${port}
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","${jar_name}"]