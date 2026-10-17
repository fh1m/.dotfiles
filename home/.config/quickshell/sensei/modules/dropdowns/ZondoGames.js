// Pure intentional-break rules; no timers, persistence or desktop access.
function rps(player, other) {
 var choices=['rock','paper','scissors'];
 if(choices.indexOf(player)<0||choices.indexOf(other)<0)throw Error('Invalid move');
 return player===other?'draw':((choices.indexOf(player)-choices.indexOf(other)+3)%3===1?'win':'loss');
}
function winner(board) {
 var lines=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
 for(var i=0;i<lines.length;i++){var l=lines[i];if(board[l[0]]&&board[l[0]]===board[l[1]]&&board[l[1]]===board[l[2]])return board[l[0]];}
 return board.indexOf('')<0?'draw':'';
}
function reply(board) {
 if(winner(board))return board.slice();
 var free=[];for(var i=0;i<9;i++)if(!board[i])free.push(i);
 var choice=free.indexOf(4)>=0?4:free[0];
 for(var t=0;t<2;t++)for(var j=0;j<free.length;j++){var b=board.slice();b[free[j]]=t===0?'O':'X';if(winner(b)===(t===0?'O':'X')){choice=free[j];t=2;break;}}
 var result=board.slice();result[choice]='O';return result;
}
