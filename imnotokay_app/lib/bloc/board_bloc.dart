import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/board.dart';

part 'board_event.dart';
part 'board_state.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc() : super(BoardInitial()) {
    on<FetchBoards>(_onFetchBoards);
  }

  void _onFetchBoards(FetchBoards event, Emitter<BoardState> emit) async {
    emit(BoardLoading());
    try {
      final response =
          await http.get(Uri.parse('http://tellmebabydsm24.cafe24.com/boards'));
      // final response = await http.get(Uri.parse('http://localhost:8080/boards'));
      if (response.statusCode == 200) {
        String body = utf8.decode(response.bodyBytes); // UTF-8로 디코딩
        List<dynamic> data = json.decode(body);
        List<Board> boards = data.map((json) => Board.fromJson(json)).toList();
        emit(BoardLoaded(boards: boards));
      } else {
        emit(BoardError(message: 'Failed to load boards'));
      }
    } catch (e) {
      emit(BoardError(message: e.toString()));
    }
  }
}
