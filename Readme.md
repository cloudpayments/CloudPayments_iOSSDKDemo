##Использование

Приложение CloudPayments iOS SDK Demo демонстрирует работу SDK для платформы iOS (iPhone, iPad, iPod) с платежным шлюзом [CloudPayments](http://cloudpayments.ru)

Полная информация об использовании на сайте
[www.cloudpayments.ru/docs/mobileSDK](www.cloudpayments.ru/docs/mobileSDK)

##Установка

Сразу после `git clone https://github.com/cloudpayments/CloudPayments_iOSSDKDemo.git`
необходимо инициализировать и скачать подмодули git. Для этого переходим в папку с проектом

``` bash
cd CloudPayments_iOSSDKDemo
```
а уже там:

```bash
git submodule update --init CloudPaymentsAPIDemo/Libraries/AFNetworking/
git submodule update --init CloudPaymentsAPIDemo/Libraries/SVProgressHUD/
```


##Описание работы приложения с SDK CloudPayments

SDK CloudPayments (CloudPaymentsAPI.framework) позволяет

* проводить проверку карточного номера на корректность
``` objc
	[CPService isCardNumberValid: cardNumberString];
```

* определять тип платежной системы
``` objc
	[CPService cardTypeFromCardNumber:cardNumberString];
```

* шифровать карточные данные и создавать криптограмму для отправки на сервер
``` objc
	CPService *_apiService = [[CPService alloc] init];
	NSString *cryptogramPacket = [_apiService makeCardCryptogramPacket:self.cardNumberString
															andExpDate:self.cardExpirationDateString
																andCVV:self.cardCVVString
													  andStorePublicID:_apiPublicID];
```

Пример использования SDK и API CloudPayments дан в файле `CPViewController`

Демо-приложение представляет из себя форму для ввода карточных данных и обработчик запросов к API CloudPayments.

Перед началом оплаты необходимо определить переменные (их значения можно взять из личного кабинета):

``` objc
	NSString *_apiPublicID = @"pk_0000000000000000000000";
	NSString *_apiSecret = @"00000000000000000000000000000000";
```

После этого необходимо инициализировать SDK CloudPayments:

```objc
CPService *_apiService = [[CPService alloc] init];
```

Вдальнейшем `_apiService` используется для создания пакета криптограммы.

##Проведение оплаты

Проведение оплаты описано в методе `makePaymentAction`.
Пояснения к описанию метода.

1. В демо-приложении словарь `paramsDictionary` содержит только обязательные параметры для запроса. Список всех возможных параметров представлен [http://cloudpayments.ru/Docs/Api#payWithCrypto](http://cloudpayments.ru/Docs/Api#payWithCrypto)
2. Метод для проведения 3DS-авторизации `-(void) make3DSPaymentWithAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString`
3. Обработка ответа банка происходит в `-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType`
4. Метод для проведения окончания 3DS-авторизации `-(void) complete3DSPaymentWithPaResString: (NSString *) paResString andTransactionIdString: (NSString *) transactionIdString`


## Ключевые моменты
1. Библиотека поставляется в виде .framework, который скомпилирован для трех текущих архитектур процессора armv7, armv7s, arm64 и i385, x86_64. Таким образом тестировать можно в iPhone Simulator. Библиотека может работать только в версиях  iOS 6.0+. iOS 8 также поддерживается.
2. В демо-проекте для сетевого взаимодействия используется библиотека AFNetworing (см. [https://github.com/AFNetworking/AFNetworking](https://github.com/AFNetworking/AFNetworking)). Все права на код этой библиотеки принадлежат авторам библиотеки.
3. В демо-проекте для показа экранных уведомлений используется библиотека SVProgressHUD (см. [https://github.com/TransitApp/SVProgressHUD](https://github.com/TransitApp/SVProgressHUD)). Все права на код этой библиотеки принадлежат авторам библиотеки.