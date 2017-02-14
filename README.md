# OJAnalyzer

Online Judge Analyser and Crawler  
AtCoder用のコードしかないです．

## Installation

    $ git clone git@github.com:hadrori/ojanalyzer.git

And then execute:

    $ cd ojanalyzer
    $ ./bin/setup

## Usage

Run Console (pry)

    $ bin/console

### Crawler

コンテストの情報と，提出の情報をとってきます．たくさんあるので時間がかかります．

    $ OJAnalyzer::Cralwer::AtCoder.new.run

### Model

#### AtCoder::Contest
- domain : コンテストのドメイン．abc001みたいな
- start_at : コンテスト開始時刻
- finish_at : コンテストの終了時刻

#### AtCoder::Submission
- contest_id : AtCoder::Contestのidを指します．実際のコンテストとは関係ないです．
- submission_id : 提出id
- problem_id : AtCoderでつかわれてる問題のid
- user_id : 提出者の名前
- language : 提出言語
- verdict : 判定
- submission_time : 提出時刻

### Analyzer

#### Tokenizer

C++のコードを簡単に字句解析をします．スペースの個数もとれます．.9みたいなドットからはじまる数値は面倒だったので対応してません．  
結果は
```ruby
[["int", "reserved"], [" ", "blank"], ["main", "name"], ... ]
```
みたいなかんじで，[単語, タグ]のペアの配列が得られます．

#### FeatureExtracter
C++コードから特徴量をとります．数値の列が得られます．

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hadrori/ojanalyzer.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

