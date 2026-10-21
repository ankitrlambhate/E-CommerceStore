# ---- build stage: compile the React app ----
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install --no-audit --no-fund
COPY . .
# The browser calls the backends through nginx path prefixes (see nginx.conf),
# so the same image works on any host/IP without rebuilding.
ENV CI=false \
    DISABLE_ESLINT_PLUGIN=true \
    REACT_APP_USER_SERVICE_URL=/svc/user \
    REACT_APP_PRODUCT_SERVICE_URL=/svc/product \
    REACT_APP_CART_SERVICE_URL=/svc/cart \
    REACT_APP_ORDER_SERVICE_URL=/svc/order
RUN npm run build

# ---- runtime stage: serve with nginx ----
FROM nginx:1.25-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
