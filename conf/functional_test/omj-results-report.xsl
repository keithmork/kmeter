<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

<!-- 
	修改自JMeter自带模板 extras/jmeter-results-report_21.xsl
	适用于JMeter 2.13生成的XML报告文件

	原XSLT模板有严重的性能问题，把模糊的XPath定位全换掉，加了索引
	实测4w条记录的jtl文件，出报告的速度从原来30分钟缩短到不到10秒

	为了简洁，把XSLT 1.0换成2.0，JMeter自带的xalan包处理不了，需要saxon包
	去掉了每个请求详情（太多了），增加了TPS、失败请求的返回内容、测试相关信息、结果文件和图表的展示等
	Keith Mo
	2016-05-20
 -->
<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN" />

<!-- 原模板里的参数，ant脚本会覆盖掉，用来控制标题显示 -->
<xsl:param name="titleReport" select="'Load Test Results'"/>
<xsl:param name="dateReport" select="'date not defined'"/>
<!-- 新加的，同样用来显示，等着被覆盖 -->
<xsl:param name="test_machine_num" select="NaN"/>
<xsl:param name="hosts" select="NaN"/>
<xsl:param name="thread" select="NaN"/>
<xsl:param name="rampup" select="NaN"/>
<xsl:param name="duration" select="NaN"/>
<xsl:param name="think_time" select="NaN"/>

<!-- 网页内容 -->
<xsl:template match="testResults">
	<html>
		<head>
			<title><xsl:value-of select="$titleReport" /></title>
			<style type="text/css">
				body {
					font:normal 75% 微软雅黑,宋体,verdana,arial,helvetica;
					color:#000000;
				}
				table tr td, table tr th {
					font-size: 75%;
				}
				table.details tr th{
			    color: #ffffff;
					font-weight: bold;
					text-align:center;
					background:#2674a6;
					white-space: nowrap;
				}
				table.details tr td{
					background:#eeeee0;
					word-wrap:break-word;
					white-space: pre-line;
					text-align: center;
				}
				h1 {
					margin: 0px 0px 5px; font: 165% verdana,arial,helvetica
				}
				h2 {
					margin-top: 1em; margin-bottom: 0.5em; font: bold 125% verdana,arial,helvetica
				}
				h3 {
					margin-bottom: 0.5em; font: bold 115% verdana,arial,helvetica
				}
				.Failure {
					font-weight:bold; color:red;
				}
				.section {
					width: 95%; 
					margin: auto;
				}
				.name, table.details td.name {
					text-align: left;
				}
				.info div {
					display: inline-block;
					line-height: 25px;
				}
				.info .name {
					width: 15%;
				}
				.chartCard { 
					margin: 0;
					padding: 0 5px 30px 5px;
					display: inline-block;
					vertical-align: top;
					width: 400px;
				}
				.chart {
					width: 400px; 
					margin: auto;
				}
				.chart img {
					width: 400px; 
					height: 300px;
				}
				.chartName, .charName td {
					font-weight:bold; 
					text-align: center;
					margin: 5px auto;
				}
				.comment, table.details td.comment {
					text-align: left;
					word-wrap: break-word;
					white-space: pre-line;
				}
			</style>
		</head>
		<body>
		
			<xsl:call-template name="pageHeader" />
			
			<xsl:call-template name="summary" />
			<hr size="1" width="95%" align="center" />
			<xsl:call-template name="info" />
			<hr size="1" width="95%" align="center" />
			
			<xsl:call-template name="pagelist" />
			<hr size="1" width="95%" align="center" />

			<xsl:call-template name="resource" />
			<hr size="1" width="95%" align="center" />

			<xsl:call-template name="chart" />
			<hr size="1" width="95%" align="center" />
			
			<xsl:call-template name="detail" />

		</body>
	</html>
</xsl:template>


<!-- 索引要用到的数据 -->
<!-- 所有http请求，以是否成功筛选（只有这字段相对固定，就 true false 2种情况） -->
<xsl:key name="sampleList" match="/testResults/httpSample" use="@s" />

<!-- 定义变量 -->
<!-- 不同状态的请求集合 -->
<xsl:variable name="allSuccessSamples" select="key('sampleList', 'true')" />
<xsl:variable name="allFailureSamples" select="key('sampleList', 'false')" />
<xsl:variable name="allSamples" select="$allSuccessSamples | $allFailureSamples" />
<!-- 各种统计数据 -->
<xsl:variable name="allCount" select="count($allSamples)" />
<xsl:variable name="allFailureCount" select="count($allFailureSamples)" />
<xsl:variable name="allSuccessCount" select="$allCount - $allFailureCount" />
<!-- 测试开始和结束时间戳 -->
<xsl:variable name="testStartTime" select="min($allSamples/@ts)" />
<xsl:variable name="testEndTime" select="max($allSamples/@ts)" />


<!-- 网页显示用到的模板 -->
<!-- 标题 -->
<xsl:template name="pageHeader">
	<h1><xsl:value-of select="$titleReport" /></h1>
	<table width="100%">
		<tr>
			<td class="name">Date report: <xsl:value-of select="$dateReport" /></td>
			<td align="right">Designed for use with <a href="http://jmeter.apache.org/">JMeter</a> and <a href="http://ant.apache.org">Ant</a>.</td>
		</tr>
	</table>
	<hr size="1" />
</xsl:template>


<!-- 所有接口数据汇总 -->
<xsl:template name="summary">
	<h2>总览</h2>
	<table align="center" class="section details" border="0" cellpadding="5" cellspacing="2">
		<tr valign="top">
			<th>请求数</th>
			<th>失败</th>
			<th>成功率</th>
			<th>平均</th>
			<th>最小</th>
			<th>最大</th>
			<th>每秒事务数</th>
		</tr>
		<tr valign="top">
			<xsl:variable name="allSuccessPercent" select="$allSuccessCount div $allCount" />
			<xsl:variable name="allTotalTime" select="sum($allSuccessSamples/@t | $allFailureSamples/@t)" />
			<xsl:variable name="allAverageTime" select="$allTotalTime div $allCount" />
			<xsl:variable name="allMinTime" select="min($allSamples/@t)" />
			<xsl:variable name="allMaxTime" select="max($allSamples/@t)" />
			<xsl:variable name="allTps">
				<xsl:call-template name="calcTPS">
					<xsl:with-param name="samplesCount" select="$allCount"/>
					<xsl:with-param name="samples" select="$allSamples"/>
				</xsl:call-template>
			</xsl:variable>

			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="$allFailureCount &gt; 0">Failure</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<td>
				<xsl:value-of select="$allCount" />
			</td>
			<td>
				<xsl:value-of select="$allFailureCount" />
			</td>
			<td>
				<xsl:call-template name="display-percent">
					<xsl:with-param name="value" select="$allSuccessPercent" />
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="display-time">
					<xsl:with-param name="value" select="$allAverageTime" />
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="display-time">
					<xsl:with-param name="value" select="$allMinTime" />
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="display-time">
					<xsl:with-param name="value" select="$allMaxTime" />
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="display-tps">
					<xsl:with-param name="value" select="$allTps" />
				</xsl:call-template>
			</td>
		</tr>
	</table>
</xsl:template>


<!-- 测试相关信息 -->
<xsl:template name="info">
	<div class="section">
		<div class="info">
			<div class="name">线程数：</div>
			<div>
				<xsl:value-of select="$thread" /> /每机器
			</div>
		</div>
		<div class="info">
			<div class="name">压测机器数：</div>
			<div>
				<xsl:value-of select="$test_machine_num" />
			</div>
		</div>
		<div class="info">
			<div class="name">持续时间：</div>
			<div>
				<xsl:value-of select="$duration" /> s
			</div>
		</div>
		<div class="info">
			<div class="name">线程集合时间：</div>
			<div>
				<xsl:value-of select="$rampup" /> s
			</div>
		</div>
		<div class="info">
			<div class="name">思考时间：</div>
			<div>
				<xsl:value-of select="$think_time" /> ms
			</div>
		</div>
		<div class="info">
			<div class="name">压测机器列表：</div>
			<div>
				<xsl:value-of select="$hosts" />
			</div>
		</div>
	</div>
</xsl:template>


<!-- 各个接口的数据 -->
<xsl:template name="pagelist">
	<h2>各用例</h2>
	<table align="center" class="section details" border="0" cellpadding="5" cellspacing="2">
		<tr valign="top">
			<th>名称</th>
			<th>请求数</th>
			<th>失败</th>
			<th>成功率</th>
			<th>平均</th>
			<th>最小</th>
			<th>最大</th>
			<th>每秒事务数</th>
		</tr>
		<!-- 按请求的标签分组 -->
		<xsl:for-each-group select="$allSamples" group-by="@lb">
			<xsl:variable name="samplesSameLabel" select="$allSamples[@lb = current()/@lb]" />
			<xsl:variable name="failureSamples" select="$samplesSameLabel[@s = 'false']" />

			<xsl:variable name="label" select="@lb" />
			<xsl:variable name="count" select="count($samplesSameLabel)" />
			<xsl:variable name="failureCount" select="count($failureSamples)" />
			<xsl:variable name="successCount" select="$count - $failureCount" />
			<xsl:variable name="successPercent" select="$successCount div $count" />
			<xsl:variable name="totalTime" select="sum($samplesSameLabel/@t)" />
			<xsl:variable name="averageTime" select="$totalTime div $count" />
			<xsl:variable name="minTime" select="min($samplesSameLabel/@t)" />
			<xsl:variable name="maxTime" select="max($samplesSameLabel/@t)" />
			<xsl:variable name="tps">
				<xsl:call-template name="calcTPS">
					<xsl:with-param name="samplesCount" select="$count"/>
					<xsl:with-param name="samples" select="$samplesSameLabel"/>
				</xsl:call-template>
			</xsl:variable>

			<tr valign="top">
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="$failureCount &gt; 0">Failure</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<td class="name">
					<xsl:value-of select="$label" />
				</td>
				<td>
					<xsl:value-of select="$count" />
				</td>
				<td>
					<xsl:value-of select="$failureCount" />
				</td>
				<td>
					<xsl:call-template name="display-percent">
						<xsl:with-param name="value" select="$successPercent" />
					</xsl:call-template>
				</td>
				<td>
					<xsl:call-template name="display-time">
						<xsl:with-param name="value" select="$averageTime" />
					</xsl:call-template>
				</td>
				<td>
					<xsl:call-template name="display-time">
						<xsl:with-param name="value" select="$minTime" />
					</xsl:call-template>
				</td>
				<td>
					<xsl:call-template name="display-time">
						<xsl:with-param name="value" select="$maxTime" />
					</xsl:call-template>
				</td>
				<td>
					<xsl:call-template name="display-tps">
						<xsl:with-param name="value" select="$tps" />
					</xsl:call-template>
				</td>
			</tr>
		</xsl:for-each-group>
	</table>
</xsl:template>


<!-- 资源文件 -->
<xsl:template name="resource">
	<h2>资源</h2>
	<table align="center" class="section details" border="0" cellpadding="5" cellspacing="2">
		<tr valign="top">
			<th>名称</th>
			<th>文件类型</th>
			<th>链接</th>
			<th>说明</th>
		</tr>
		<tr valign="top">
			<td class="name">综合报告（SynthesisReport）</td>
			<td>csv</td>
			<td>
				<a href="chart/SynthesisReport.csv" target="_blank">下载</a>
			</td>
			<td class="comment">用文本编辑器或Excel打开</td>
		</tr>
		<tr valign="top">
			<td class="name">原始测试记录</td>
			<td>jtl</td>
			<td>
				<a href="result_log/resultlog.jtl" target="_blank">下载</a>
			</td>
			<td class="comment">XML格式，用文本编辑器打开</td>
		</tr>
		<tr valign="top">
			<td class="name">JMeter日志文件</td>
			<td>log</td>
			<td>
				<a href="jmeter_log/jmeter.log" target="_blank">打开</a>
			</td>
			<td class="comment"></td>
		</tr>
	</table>
</xsl:template>


<!-- 图表 -->
<xsl:template name="chart">
	<h2>图表</h2>
	<div class="section">
		<div class="chartCard">
			<div class="chart">
				<a href="chart/PerfMon.png" target="_blank">
					<img src="chart/PerfMon.png" alt="PerfMon.png"/>
				</a>
			</div>
			<div class="chartName">性能监视图（PerfMon）</div>
			<div class="comment">需要被测服务器上运行PerfMonAgent，且4444端口能连通</div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/TransactionsPerSecond.png" target="_blank">
						<img src="chart/TransactionsPerSecond.png" alt="TransactionsPerSecond.png"/>
				</a>
			</div>
			<div class="chartName">每秒事务数（TransactionsPerSecond）</div>
			<div class="comment"></div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/ResponseTimesDistribution.png" target="_blank">
						<img src="chart/ResponseTimesDistribution.png" alt="ResponseTimesDistribution.png"/>
				</a>
			</div>
			<div class="chartName">响应时间分布图（ResponseTimesDistribution）</div>
			<div class="comment"></div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/ResponseTimesPercentiles.png" target="_blank">
						<img src="chart/ResponseTimesPercentiles.png" alt="ResponseTimesPercentiles.png"/>
				</a>
			</div>
			<div class="chartName">响应时间百分位图（ResponseTimesPercentiles）</div>
			<div class="comment"></div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/ResponseTimesOverTime.png" target="_blank">
						<img src="chart/ResponseTimesOverTime.png" alt="ResponseTimesOverTime.png"/>
				</a>
			</div>
			<div class="chartName">响应时间随时间变化图（ResponseTimesOverTime）</div>
			<div class="comment"></div>
		</div>
		
		<div class="chartCard">
			<div class="chart">
				<a href="chart/LatenciesOverTime.png" target="_blank">
						<img src="chart/LatenciesOverTime.png" alt="LatenciesOverTime.png"/>
				</a>
			</div>
			<div class="chartName">延时随时间变化图（LatenciesOverTime）</div>
			<div class="comment">
				JMeter里latency指准备发请求~服务器返回第1个字节的时间
			</div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/ResponseCodesPerSecond.png" target="_blank">
						<img src="chart/ResponseCodesPerSecond.png" alt="ResponseCodesPerSecond.png"/>
				</a>
			</div>
			<div class="chartName">每秒HTTP返回码（ResponseCodesPerSecond）</div>
			<div class="comment">看什么时候出现4xx、5xx</div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/BytesThroughputOverTime.png" target="_blank">
						<img src="chart/BytesThroughputOverTime.png" alt="BytesThroughputOverTime.png"/>
				</a>
			</div>
			<div class="chartName">字节吞吐量随时间变化图（BytesThroughputOverTime）</div>
			<div class="comment"></div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/HitsPerSecond.png" target="_blank">
						<img src="chart/HitsPerSecond.png" alt="HitsPerSecond.png"/>
				</a>
			</div>
			<div class="chartName">每秒发出请求数（HitsPerSecond）</div>
			<div class="comment"></div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/ThreadsStateOverTime.png" target="_blank">
						<img src="chart/ThreadsStateOverTime.png" alt="ThreadsStateOverTime.png"/>
				</a>
			</div>
			<div class="chartName">活动线程数随时间变化图（ThreadsStateOverTime）</div>
			<div class="comment"></div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/ThroughputVsThreads.png" target="_blank">
						<img src="chart/ThroughputVsThreads.png" alt="ThroughputVsThreads.png"/>
				</a>
			</div>
			<div class="chartName">每秒事务数和线程数对比图（ThroughputVsThreads）</div>
			<div class="comment">需要运行比较长时间，线程以几十秒为单位慢慢增加，这图才有意义</div>
		</div>

		<div class="chartCard">
			<div class="chart">
				<a href="chart/TimesVsThreads.png" target="_blank">
						<img src="chart/TimesVsThreads.png" alt="TimesVsThreads.png"/>
				</a>
			</div>
			<div class="chartName">响应时间和线程数对比图（TimesVsThreads）</div>
			<div class="comment">需要运行比较长时间，线程以几十秒为单位慢慢增加，这图才有意义</div>
		</div>
	</div>
</xsl:template>


<!-- 失败请求的详情 -->
<xsl:template name="detail">

	<xsl:if test="$allFailureCount &gt; 0">
		<h2>错误详情</h2>

		<xsl:for-each-group select="$allFailureSamples" group-by="@lb">
			<xsl:variable name="failureSamples" select="$allFailureSamples[@lb = current()/@lb]" />

			<xsl:variable name="failureCount" select="count($failureSamples)" />

			<xsl:if test="$failureCount &gt; 0">
				<h3><xsl:value-of select="@lb" /></h3>

				<table align="center" class="section details" border="0" cellpadding="5" cellspacing="2">
				<tr valign="top">
					<th>响应</th>
					<th>错误信息</th>
					<th>响应内容</th>
				</tr>
			
				<xsl:for-each select="$failureSamples">
					<tr>
						<td class="comment"><xsl:value-of select="@rc | @rs" /> - <xsl:value-of select="@rm" /></td>
						<td class="comment"><xsl:value-of select="assertionResult/failureMessage" /></td>
						<td class="comment"><xsl:value-of select="responseData" /></td>
					</tr>
				</xsl:for-each>
				
				</table>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:if>
</xsl:template>


<!-- 其他内部用模板 -->

<!-- 计算用 -->
<!-- 计算每秒事务数 -->
<xsl:template name="calcTPS">
	<xsl:param name="samplesCount" select="/.." />
	<xsl:param name="samples" select="/.." />

	<xsl:variable name="startTime" select="min($samples/@ts)" />
	<xsl:variable name="endTime" select="max($samples/@ts)" />
	<!-- 只发1条请求时结束时间=开始时间，这时直接用响应时间 -->
	<xsl:variable name="timeUsed" select="
		if ($endTime - $startTime &gt; 0)
		then ($endTime - $startTime) div 1000
		else $samples/@t div 1000
	"/>
	<xsl:value-of select="$samplesCount div $timeUsed"/>
</xsl:template>


<!-- 格式化数字 -->
<!-- 百分比显示 -->
<xsl:template name="display-percent">
	<xsl:param name="value" />
	<xsl:value-of select="format-number($value,'0.00%')" />
</xsl:template>

<!-- 测试结果时间显示 -->
<xsl:template name="display-time">
	<xsl:param name="value" />
	<xsl:value-of select="format-number($value,'0 ms')" />
</xsl:template>

<!-- 每秒请求数显示 -->
<xsl:template name="display-tps">
	<xsl:param name="value" />
	<xsl:value-of select="format-number($value,'0.00/s')" />
</xsl:template>
	
</xsl:stylesheet>