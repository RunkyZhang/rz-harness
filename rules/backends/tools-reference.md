# 公共工具类详细用法参考

## 3.1 JSON 操作 → `JacksonHelper`

```java
// 序列化
String json = JacksonHelper.toJson(object);
String prettyJson = JacksonHelper.toPrettyJson(object);
byte[] jsonBytes = JacksonHelper.toJsonBytes(object);

// 反序列化
T obj = JacksonHelper.toObj(json, T.class);
List<T> list = JacksonHelper.toList(json, T.class);
JsonNode node = JacksonHelper.toObj(json, true);

// 创建空节点
JacksonHelper.newArrayNode();
JacksonHelper.newJsonNode();

// 注册子类型
JacksonHelper.registerSubtype(SubClass.class, "subType");
```

**禁止**使用 `Gson`、`FastJson`、`new ObjectMapper()`。

## 3.2 对象 Copy → `BeanUtils`

```java
// 单个对象拷贝
BeanUtils.copyProperties(source, target);

// 列表拷贝（自动实例化目标类）
List<TargetDto> targetList = BeanUtils.copyProperties(sourceList, SourceDto.class, TargetDto.class);

// Bean 转 Map
Map<String, Object> map = BeanUtils.beanToMap(bean);

// 设置默认值（String→""，Integer→0，Double→0.0，Boolean→true，Date→now）
BeanUtils.defaultValue(bean);
```

**禁止**使用 Spring `BeanUtils`。

## 3.3 日期时间 → `DateTimeUtility` + `LocalDateTimeUtils`

### DateTimeUtility 常用方法

```java
// 解析与格式化
Date date = DateTimeUtility.parse("2026-01-01", DateTimeUtility.DATE_FORMAT1);
String str = DateTimeUtility.toString(date, DateTimeUtility.DATE_FORMAT1);

// 构造日期
Date now = DateTimeUtility.getNow();
Date today = DateTimeUtility.getToday();
Date minDate = DateTimeUtility.getMinDate(); // 1900-01-01
Date maxDate = DateTimeUtility.getMaxDate(); // 2099-12-31

// 日期运算
Date result = DateTimeUtility.addDay(date, 7);
Date result = DateTimeUtility.addMonth(date, 1);

// 日期比较
int days = DateTimeUtility.totalDays(startDate, endDate);
int hours = DateTimeUtility.totalHours(startDate, endDate);
int cmp = DateTimeUtility.compare(date1, date2);

// 时区转换
Date converted = DateTimeUtility.changeTimezone(date, ZoneId.of("Asia/Jakarta"), ZoneId.of("Asia/Shanghai"));
```

### LocalDateTimeUtils 常用方法

```java
// 转换
LocalDateTime ldt = LocalDateTimeUtils.convertDateToLDT(date);
Date date = LocalDateTimeUtils.convertLDTToDate(ldt);

// 格式化
String str = LocalDateTimeUtils.formatTime(ldt, "yyyy-MM-dd HH:mm:ss");
String now = LocalDateTimeUtils.formatNow("yyyy-MM-dd");

// 加减
LocalDateTime result = LocalDateTimeUtils.plus(ldt, 1, ChronoUnit.DAYS);
LocalDateTime result = LocalDateTimeUtils.minu(ldt, 1, ChronoUnit.HOURS);

// 日期边界
LocalDateTime start = LocalDateTimeUtils.getDayStart(ldt);
LocalDateTime end = LocalDateTimeUtils.getDayEnd(ldt);

// 时区转换
LocalDateTime utc = LocalDateTimeUtils.localToUtc(ldt);
LocalDateTime local = LocalDateTimeUtils.utcToLocal(utc);

// 时区失真修正（数据库存储与业务时区不一致时使用）
Date corrected = LocalDateTimeUtils.correctDate(date, sourceZoneId, targetZoneId);
LocalDateTime correctedLdt = LocalDateTimeUtils.correctLocalDateTime(ldt, sourceZoneId, targetZoneId);

// 时间差
long days = LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.DAYS);

// 日期区间重叠判断
boolean overlap = LocalDateTimeUtils.isOverlapping(start1, end1, start2, end2);

// 连续日期分组
List<DateRangeDto> ranges = LocalDateTimeUtils.getDateRanges(dateList);

// 获取指定星期几的日期
LocalDate nextMonday = LocalDateTimeUtils.getDayOfWeekDate(date, DayOfWeek.MONDAY);
```

**禁止**使用 `SimpleDateFormat`。

## 3.4 字符串判断 → `org.apache.commons.lang3.StringUtils`

```java
StringUtils.isBlank(str);
StringUtils.isNotBlank(str);
StringUtils.isEmpty(str);
StringUtils.isNotEmpty(str);
StringUtils.equals(str1, str2);
StringUtils.trim(str);
StringUtils.defaultIfBlank(str, defaultVal);
```

## 3.5 集合操作 → `CollectionUtils` + `StreamCommonUtil`

```java
// 空判断
org.springframework.util.CollectionUtils.isEmpty(collection);

// 转换列表
List<Target> targets = StreamCommonUtil.toList(sources, source -> convert(source));

// 扁平化
List<Item> items = StreamCommonUtil.reduce(listOfLists);

// 过滤
List<T> filtered = StreamCommonUtil.filterToList(list, predicate);

// 去重
List<T> distinctList = StreamCommonUtil.distinct(list);
List<T> distinctList = StreamCommonUtil.distinctByKey(list, Item::getKey);

// 分组
Map<K, List<V>> groups = StreamCommonUtil.groupToMap(list, keyMapper);

// 转 Map
Map<K, V> map = StreamCommonUtil.toMap(list, keyMapper, valueMapper);
Map<K, V> linkedMap = StreamCommonUtil.toLinkedMap(list, keyMapper, valueMapper);

// 转 Set
Set<K> set = StreamCommonUtil.toSet(list, keyMapper);

// 查找第一个
Optional<T> first = StreamCommonUtil.filterFirst(list, predicate);

// 空安全
List<T> safe = StreamCommonUtil.emptyIfNull(list);

// 分页切分（每 pageSize 条一页）
Map<Integer, List<T>> pages = StreamCommonUtil.subList(list, pageSize);

// 交集判断
boolean hasIntersection = StreamCommonUtil.hasMatch(list1, list2);
```

## 3.6 断言校验 → `AssertHelper`

```java
AssertHelper.notNull(obj, "对象不能为空");
AssertHelper.isNull(obj, "对象必须为空");
AssertHelper.notEmpty(str, "字符串不能为空");
AssertHelper.isEmpty(str, "字符串必须为空");
AssertHelper.notBlank(str, "字符串不能为空白");
AssertHelper.isBlank(str, "字符串必须为空白");
AssertHelper.isTrue(condition, "条件不满足");
AssertHelper.isFalse(condition, "条件必须为 false");
AssertHelper.check(condition, "检查不通过");
AssertHelper.equals(a, b, "不相等");
AssertHelper.notEquals(a, b, "不能相等");
AssertHelper.notEmpty(collection, "集合不能为空");
AssertHelper.isEmpty(collection, "集合必须为空");
AssertHelper.assertFail("手动失败");

// 带错误码重载
AssertHelper.notNull(obj, "错误信息", 80001L);
```

失败时自动抛出 `BusinessException`。

## 3.7 异常 → `BusinessException`

```java
// 基本构造
throw new BusinessException(code, message);
throw new BusinessException(code, message, traceMessage); // traceMessage 给开发者看的详细信息

// 设置日志级别
BusinessException ex = new BusinessException(code, message);
ex.setErrorLogLevel(true);  // true=error 日志，false=warn（默认）

// 常用静态工厂方法
BusinessException.FAILED_DESERIALIZATION_JSON           // 800006
BusinessException.FAILED_SERIALIZE_JSON                  // 800007
BusinessException.FAILED_INVOKE_RPC_API_WITH_RESULT(...) // 800012
BusinessException.API_FLOW_LIMITING                      // 800013
BusinessException.INVOKE_FLOW_BREAKING                   // 800014
BusinessException.INVALID_RABBITMQ_DELAY_TIME            // 800015
BusinessException.FAILED_TO_BUILD_CONFIG_SERVICE         // 800017
BusinessException.FAILED_TO_INVOKE_BY_CONFIG_SERVICE     // 800017
BusinessException.FAILED_TO_CONVERT_URL_RESOURCE_TO_BASE64 // 800018
BusinessException.FAILED_TO_SEND_MESSAGE_TO_KAFKA        // 800019
BusinessException.FAILED_INVOKE_RPC_API_TIMEOUT          // 800020
```

**禁止** catch 后吞掉异常不处理，无法处理的异常往上抛。

## 3.8 Redis 操作 → `RedisMapper`

```java
@Autowired
private RedisMapper redisMapper;
```

**禁止**直接使用 `RedisTemplate`。

## 3.9 本地缓存 → `@LocalCacheable`

```java
@LocalCacheable(keyExpression = "#orderId", expireTime = 300)
public Entity getByOrderId(String orderId) {
    return mapper.selectByOrderId(orderId);
}
```

- `keyExpression`：SpEL 表达式，指定缓存 key
- `expireTime`：过期时间（秒），0 = 永不过期
- 内置：定时刷新 + 失败兜底（使用旧缓存）+ 熔断保护（连续失败 3 次后熔断）
- 缓存管理：通过 `LocalCacheManager` 手动刷新/过期/清除缓存

## 3.10 安全/加密 → `Helper`

```java
// 哈希
String sha1 = Helper.sha1Encode(input);
String md5 = Helper.md5Encode(input);
String sha256 = Helper.sha256Encode(input);
String hmac256 = Helper.hmac256Encode(input, key);

// Base64
String base64 = Helper.toBase64(bytes);
byte[] bytes = Helper.base64ToBytes(base64Str);
byte[] hexBytes = Helper.toHexString(bytes);

// Trace 生成
String traceId = Helper.generateTraceId();
String spanId = Helper.generateSpanId();

// 本机 IP
String ip = Helper.getIpV4();

// RPC 结果安全提取（含错误处理）
T data = Helper.getResultData(rpcResult, true); // throwing=true 时失败抛异常

// URL 资源加载
byte[] data = Helper.urlResourceToBytes(url);
String base64str = Helper.urlResourceToBase64(url);

// 反射工具
List<Field> fields = Helper.getFields(SomeClass.class);
List<Method> methods = Helper.getMethods(SomeClass.class);
```

## 3.11 其他工具类详解

### TxUtils — 事务工具

```java
// 判断是否在事务中
boolean inTx = TxUtils.isTxActive();

// 事务提交后执行（异步，推荐）
TxUtils.runAfterTxSuccess(() -> {
    // 发送 MQ、刷新缓存、触发后续流程
});

// 事务提交后执行（同步）
TxUtils.runAfterTxSuccess(() -> { ... }, false);
```

### EnumCommonUtil — 枚举工具

```java
// 按名称查找枚举
StringEnum e = EnumCommonUtil.findEnumByName("ENUM_NAME");

// 按类型值获取枚举
SomeEnum e = EnumCommonUtil.getEnumByType(type, SomeEnum.class);

// 获取枚举描述
String desc = EnumCommonUtil.getDescByType(type, SomeEnum.class);

// 枚举转前端下拉列表
List<CommonLabelValueDTO> options = EnumCommonUtil.getCommonLabelValueVOs(SomeEnum.class);

// 校验枚举值是否合法
boolean valid = EnumCommonUtil.isValidEnumValue(type, SomeEnum.class);
```

### TraceUtils — TraceId 工具

```java
String traceId = TraceUtils.getTraceId();
```

### AsyncWorker — 异步任务

```java
@Autowired
private AsyncWorker asyncWorker;

// 无返回值的异步任务
asyncWorker.execute(() -> { /* 耗时操作 */ });

// 有返回值的异步任务
Future<T> future = asyncWorker.submit(() -> { return computeResult(); });
```

### SpringContextHelper — Bean 获取

```java
SomeBean bean = SpringContextHelper.getBean(SomeBean.class);
SomeBean bean = SpringContextHelper.getBean("beanName", SomeBean.class);
Object bean = SpringContextHelper.getBean("beanName");
```

### LocalizedText — i18n 文本

```java
@Autowired
private LocalizedText localizedText;

// 按当前语言获取
String text = localizedText.getValue("error.key", "默认错误信息");

// 指定语言获取
String text = localizedText.getValue("zh_CN", "error.key", "默认错误信息");

// 指定 namespace
String text = localizedText.getValue("custom-ns", "zh_CN", "error.key", "默认值");
```

## 3.12 Bean 注入

```java
@Resource
private SomeService someService;
```

尽量避免使用 `@Autowired`。
