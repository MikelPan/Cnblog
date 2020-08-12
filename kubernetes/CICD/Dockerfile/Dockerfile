FROM java:openjdk-8-jre-alpine
ARG jar_name
ARG port
ENV jar_name=${jar_name} \
    port=${port}
ADD ./${jar_name} /apps/
WORKDIR /apps
EXPOSE ${port}
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","${jar_name}"]