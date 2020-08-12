FROM java:openjdk-8-jre-alpine
ARG JAR_NAME
ARG JAR_DIR
ARG PORT
ENV JAVA_OPTS="" \
    JAR_NAME=$JAR_NAME \
    PORT=$PORT
WORKDIR /apps
ADD ${JAR_DIR}/${JAR_NAME} /apps/
RUN ls -la /apps
EXPOSE $PORT
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar $JAR_NAME"]