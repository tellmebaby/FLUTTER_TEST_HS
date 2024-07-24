part of 'board_bloc.dart';

abstract class BoardState extends Equatable {
  const BoardState();
  
  @override
  List<Object> get props => [];
}

class BoardInitial extends BoardState {}

class BoardLoading extends BoardState {}

class BoardLoaded extends BoardState {
  final List<Board> boards;

  const BoardLoaded({required this.boards});

  @override
  List<Object> get props => [boards];
}

class BoardError extends BoardState {
  final String message;

  const BoardError({required this.message});

  @override
  List<Object> get props => [message];
}