FROM payara/micro:6.2025.1-jdk21
COPY --chown=payara:payara chat-webapp.war ${DEPLOY_DIR}
CMD [ "--contextroot", "chat","--deploy", "/opt/payara/deployments/chat-webapp.war" ]
