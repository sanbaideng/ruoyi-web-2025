<template>
	<div class="document-container" v-if="fileList.length === 0">
		<n-upload action="/api/system/user/edit/avatar" :max=1 directory-dnd :default-file-list="fileList"
			:headers="headers" @finish="handleFinish">
			<n-upload-dragger>
				<div class="document-container-img">
					<img src="@/assets/fileType.png" alt="">
				</div>
				<div>
					<n-p depth="3" style="margin: 8px 0 0 0">
						点击或拖拽上传，即享翻译与AI问答
					</n-p>
				</div>
				<n-p depth="3" style="margin: 8px 0 0 0">支持 pdf, word, ppt, xls,txt,epub,srt,xml 多种格式文档</n-p>
			</n-upload-dragger>
		</n-upload>
	</div>
	<div class="document-containers" v-else>
		<div class="name-fileList">
			<div v-for="item in 2" class="file-item" :class="{ 'file-item-selected': selectedFileId === item }"
				@click="selectedFileId = item" :key="item">
				<p class="file-name">文件名称{{ item }}</p>
				<p class="file-id">时间：2025/1/9</p>
			</div>
		</div>
		<div class="name-content">
			<div :style="{ borderRight: aiAnswer ? '1px dashed #ccc' : 'none' }">
				<div v-if="isPdfLoaded" style="height: calc(100vh - 120px)">
					<component :is="pdfComponent" :src="pdf" @rendered="rendered" />
				</div>
				<div v-else style="height: calc(100vh - 120px); display: flex; justify-content: center; align-items: center;">
					<p>PDF预览加载中...</p>
				</div>
			</div>
			<div v-if="aiAnswer">2</div>
		</div>
		<div class="name-button">
			<n-button strong secondary round type="success" style="margin-bottom: 10px;"
				@click="aiAnswer = !aiAnswer">AI问答</n-button>
			<n-button strong secondary round type="success">下载文档</n-button>
		</div>
	</div>
</template>

<script setup lang="ts">
import { ref, shallowRef, onMounted } from 'vue'
import { NUpload, UploadFileInfo, useMessage, NUploadDragger, NP, NButton } from 'naive-ui'
import { getToken } from '@/store/modules/auth/helper'

const message = useMessage()
const token = getToken()
const headers = {
	Authorization: `Bearer ${token}`
}
let aiAnswer = ref(false)
let pdf = ref('http://static.shanhuxueyuan.com/test.pdf')
const selectedFileId = ref<number | null>(1)
const pdfComponent = shallowRef(null)
const isPdfLoaded = ref(false)

// Dynamically import the PDF component
onMounted(async () => {
	try {
		const module = await import('@vue-office/pdf').catch(() => {
			console.warn('Failed to load @vue-office/pdf module')
			return { default: null }
		})
		
		if (module.default) {
			pdfComponent.value = module.default
			isPdfLoaded.value = true
		}
	} catch (error) {
		console.error('Error loading PDF component:', error)
	}
})

function rendered(e: any) {
	console.log(e)
}

let fileList = ref<UploadFileInfo[]>([
	{
		id: 'avatar',
		name: '头像预览',
		status: 'finished',
		url: 'http://panda-1253683406.cos.ap-guangzhou.myqcloud.com/panda/2024/01/03/0e3600b455914b0dade9943f281be19b.png'
	},
])

function handleFinish({
	event
}: {
	file: UploadFileInfo
	event?: ProgressEvent
}) {
	const ext = (event?.target as XMLHttpRequest).response
	let file = {
		id: 'avatar',
		name: '头像预览',
		status: 'finished',
		url: ext
	}
	fileList.value.push(file as UploadFileInfo)
	message.success('上传成功！')
}
</script>

<style scoped lang="less">
.document-container {
	height: calc(100vh - 100px);

	.document-container-img {
		display: flex;
		justify-content: center;
		align-items: center;
		height: auto;
		width: 300px;
		margin: 0 auto;
	}
}

.document-containers {
	height: calc(100vh - 100px);
	display: flex;
	justify-content: space-between;
	border: 1px solid #ccc;
	border-radius: 10px;

	div {
		padding: 10px;
	}

	.name-fileList {
		width: 300px;
		height: 100%;
		border-right: 1px solid #ccc;

		.file-item {
			border: 1px solid #ccc;
			margin-bottom: 10px;
			border-radius: 10px;
			cursor: pointer;
		}

		.file-item:hover {
			background-color: #19bdee;
		}

		.file-item-selected {
			background-color: #19bdee;
			color: white;
		}

	}

	.name-content {
		width: 100%;
		height: 100%;
		display: flex;
		justify-content: space-between;

		div:nth-child(1) {
			flex: 1;
			padding: 0;
		}

		div:nth-child(2) {
			flex: 1;
			padding: 0 0 0 10px;
			border-left: 1px dashed #ccc;
		}
	}

	.name-button {
		width: 150px;
		height: 100%;
		border-left: 1px solid #ccc;
	}
}
</style>
