class Board {
  final int? no;
  final String? title;
  final String? writer;
  final String? content;
  final DateTime? regDate;
  final DateTime? updDate;
  final int? views;

  Board({
    this.no,
    this.title,
    this.writer,
    this.content,
    this.regDate,
    this.updDate,
    this.views,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      no: json['no'] as int?,
      title: json['title'] as String?,
      writer: json['writer'] as String?,
      content: json['content'] as String?,
      regDate: json['regDate'] != null ? DateTime.parse(json['regDate']) : null,
      updDate: json['updDate'] != null ? DateTime.parse(json['updDate']) : null,
      views: json['views'] as int?,
    );
  }
}