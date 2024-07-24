part of 'board_bloc.dart';

abstract class BoardEvent extends Equatable {
  const BoardEvent();

  @override
  List<Object> get props => [];
}

class FetchBoards extends BoardEvent {}