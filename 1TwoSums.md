### Step 1
- 真っ先に思いついたのは、二重ループによる全探索。
- 二重ループはやりたくない、、
- numとそのインデックスをhashmapに一通り記録した後、任意のnumに対してtargetとの差がhashmapにあるかどうかを調べる方法ならO(n)でできる
  - 今回|n|の最大値は10^4なので、Goなら0.2msで実行時間を見積もれる
  - ちなみにO(n^2)でも2秒でできる計算
- 空間計算量：O(n)
- 問題の条件で気になったところ（面接だったら面接官に確認していただろう点）は、
  - numsはソートされているかどうか？ソートされているなら前と後ろ同時に探索していく手法もアリ
    - 時間計算量：O(n)、空間計算量：O(1)
  - 答えは必ず存在するのか？存在するなら一意に定まるか？
    - target=4, nums=[1,2,2,3]だと困る
    - 必ず存在して一意に定まると問題文に明記してあったが、コンパイラはそのことを知らないので、答えを見つけたらループから抜け出してからreturnするようにした

```Go
func twoSum(nums []int, target int) []int {
    numToIndices := make(map[int][]int)
    for i, n := range nums {
        numToIndices[n] = append(numToIndices[n], i)
    }

    ans := []int{}
    for n, indices := range numToIndices {
        if n * 2 == target && len(indices) == 2 {
            ans = append(ans, numToIndices[n]...)
            break
        }
        dif := target - n
        if _, exist := numToIndices[dif]; exist && n * 2 != target {
            ans = append(ans, indices[0])
            ans = append(ans, numToIndices[dif][0])
            break
        }
    }
    return ans
}
```

### Step 2
- Discord検索の時間
- https://github.com/seal-azarashi/leetcode/pull/11/files 参照
  - step1の二つのループを一つにまとめている
  - このくらいは自力で思いつきたいところ、、
- https://discord.com/channels/1084280443945353267/1237649827240742942/1249892025948573706
  - こういった身体性を持つというか、実世界に例えてみる想像力はアルゴリズムを思いつくときに非常に有用だなと思った
- 答えが存在しない場合にpanicするコードを書いている人を見かけたので、自分もやってみることに
  - 以前からleetcodeをやっているとエラーハンドリングについてのセンスが磨かれないなという点を問題点だと思っていた

```Go
func twoSum(nums []int, target int) []int {
    numToIdx := make(map[int]int)
    for i, n := range nums {
        dif := target - n
        if _, exist := numToIdx[dif]; exist {
            return []int{i, numToIdx[dif]}
        }
        numToIdx[n] = i
    }
    
    log.Panic("No pair of num adds up to the target.")
    return []int{}
}
```

- ソートしてから前と後ろから探すバージョンも実装しようかと思ったが、初めからソートされているならin-placeかつ線形時間で実装できるが、
今回はソートにO(nlogn)時間使い、インデックス情報も保持しないといけないので空間計算量もO(n)となり、パフォーマンスが明らかに上記の解法に劣るので実装しないことに

### Step 3
- 最終的なコード

```Go
func twoSum(nums []int, target int) []int {
    numToIdx := make(map[int]int)
    for i, n := range nums {
        dif := target - n
        if _, exist := numToIdx[dif]; exist {
            return []int{i, numToIdx[dif]}
        }
        numToIdx[n] = i
    }

    log.Panic("No valid pair found.")
    return []int{}
}
```
