FROM java:openjdk-8-jre-alpine
ARG PORT
ARG JAR_NAME
ARG JAR_DIR
ENV JAVA_OPTS=""
ADD ${JAR_DIR}/${JAR_NAME} /apps
WORKDIR /apps
EXPOSE ${PORT}
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar $JAR_NAME"]