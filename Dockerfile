FROM node:20-alpine AS builder

ARG NODE_ENV=production

WORKDIR /summaly

RUN apk add --no-cache ca-certificates git alpine-sdk g++ build-base cmake clang libressl-dev python3
RUN git clone https://github.com/misskey-dev/summaly.git
RUN cd summaly
RUN npm run build || echo "Done."
RUN rm -rf .git

FROM node:20-alpine AS runner

ARG UID="622"
ARG GID="622"

RUN apk add --no-cache ca-certificates tini \
        && addgroup -g "${GID}" summaly \
        && adduser -u "${UID}" -G summaly -D -h /summaly summaly

USER summaly
WORKDIR /
COPY --chown=summaly:summaly --from=builder /summaly ./

WORKDIR /summaly
RUN NODE_ENV=development npm install

ENV NODE_ENV=production
ENV FASTIFY_ADDRESS=0.0.0.0
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["npm", "run", "serve"]
