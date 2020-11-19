### Vue 实例介绍
#### 简单实例
```html
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title></title>
	</head>
	<body>
		<!--这是我们的View-->
		<div id="app">
			<h1>{{ title }}</h1>
		</div>
	</body>
	<script src="https://cdn.bootcdn.net/ajax/libs/vue/2.6.12/vue.js"></script>
	<script tyep="text/javascript">
		// 创建一个 Vue 实例
        var vm = new Vue({
            el: '#app',
            data () {
                return {
                    title: 'Hello World'
                }
            }
        })
	</script>
</html>
```