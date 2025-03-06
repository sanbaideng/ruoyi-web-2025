# 构建阶段
FROM node:16-alpine as builder

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json (如果存在)
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制源代码
COPY . .

# 构建项目
RUN npm run build

# 部署阶段
FROM nginx:alpine

# 将构建阶段生成的dist文件复制到nginx的html目录下的web目录中
COPY --from=builder /app/dist/ /usr/share/nginx/html/web/

# 用本地的nginx.conf配置来替换nginx镜像里的默认配置
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露8081端口
EXPOSE 8081

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
