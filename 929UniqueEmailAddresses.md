### Step 1
- まず考えたのは、emailを最も単純な形に変換し、単純化されたメールアドレスを集合に溜めていき、最終的に集合の中の要素数を返す方法
- テストで2回こけた
  - 実装はスムーズに進んだが、メアドを単純化する部分の処理の順番が間違っており、ドメインが返されないようになってしまっていたので修正
  - `for _, _ := range simplifiedEmails`としていたが、新しく宣言している変数がないので、`:=`ではなく、`=`にしないといけなかった
- [Googleのスタイルガイド](https://google.github.io/styleguide/go/decisions)に
> Omit types and type-like words from most variable names.
For a number, userCount is a better name than numUsers or usersInt.

とあったので、`distinctSimplifiedEmailsNum`としようとしたところを`distinctSimplifiedEmails`とした

```Go
// Go

func numUniqueEmails(emails []string) int {
	simplifiedEmails := make(map[string]struct{})
	for _, email := range emails {
		email := simplifyEmailAddress(email)
		simplifiedEmails[email] = struct{}{}
	}

	distinctSimplifiedEmails := 0
	for _, _ = range simplifiedEmails {
		distinctSimplifiedEmails++
	}
	return distinctSimplifiedEmails
}

func simplifyEmailAddress(email string) string {
	simplifiedEmail := ""
	localOrDomain := "local"
	afterPlusMark := false

	for _, c := range email {
		if c == '@' {
			localOrDomain = "domain"
		}
		if localOrDomain == "local" && (afterPlusMark || c == '.') {
			continue
		}
		if localOrDomain == "local" && c == '+' {
			afterPlusMark = true
			continue
		}

		simplifiedEmail += string(c)
	}

	return simplifiedEmail
}
```

