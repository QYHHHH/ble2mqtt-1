FROM node:lts-alpine@sha256:8c94a0291133e16b92be5c667e0bc35930940dfa7be544fb142e25f8e4510a45 as build-container
RUN apk add --no-cache --update bluez python build-base

WORKDIR "/app"

COPY package*.json "/app/"
RUN npm i -g npm && \
    npm ci

COPY . "/app/"
RUN npm run build && \
    rm -rf ./.github ./src ./test ./node_modules


FROM node:lts-alpine@sha256:8c94a0291133e16b92be5c667e0bc35930940dfa7be544fb142e25f8e4510a45
RUN apk add --no-cache --update bluez python build-base

ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV
WORKDIR "/app"

RUN apk add --no-cache --update dumb-init && \
    ln -s /app/dist/bin/ble2mqtt.cjs /usr/local/bin/ble2mqtt

COPY --from=build-container /app/package*.json "/app/"
RUN npm i -g npm && \
    npm ci --only-production

COPY --from=build-container "/app" "/app"
USER node

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/ble2mqtt"]
