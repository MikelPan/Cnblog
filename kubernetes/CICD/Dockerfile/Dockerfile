FROM java:openjdk-8-jre-alpine
ARG jar_dir
ARG jar_name
ARG port
ENV jar_dir=${jar_dir} \
    jar_name=${jar_name} \
    port=${port}
ADD ${jar_dir}/${jar_name} /apps/
WORKDIR /apps
EXPOSE ${port}
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","${jar_name}"]