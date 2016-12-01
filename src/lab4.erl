%% @author DAT 
-module(lab4).  
-export([make_request/2, getAttackedBy/3, 
		 game/0, archer/1, boss/1, healer/1, start/0, tanker/1,  
		 startArcher/0, startBoss/0, startGame/0, startHealer/0, startTanker/0]).
 

make_request(Id, Msg) -> Id ! Msg. 

getAttackedBy(0, Host, Attacker) -> io:format("~n~s: I'm dead @_o. Got attacked by: ~s", [Host, Attacker]);

getAttackedBy(HP, Host, Attacker) -> io:format("~n~s(~w): Get attacked by ~s", [Host, HP, Attacker]).
  
game() ->
	io:format("~nGame: waiting", []),
    receive
        {game_started, Tanker_Pid} -> 
			io:format("~nGame: started", []), 
			make_request(Tanker_Pid, game_started)  
    end.

tanker(0) -> Boss_Pid = global:whereis_name(boss_pid), 
			 make_request(Boss_Pid, tanker_dead),
			 io:format("~nTanker: I'm dead @_o Boss Won. Game Over!", []); 

tanker(TANKER_HP) ->
	io:format("~nTanker(~w): wating", [TANKER_HP]),  
	receive  
		boss_dead -> io:format("~nGame Over! Tanker Won", []);
		
		game_started -> io:format("~nTanker: Game started! Attacking Boss", []),
						Boss_Pid = global:whereis_name(boss_pid),
						make_request(Boss_Pid, get_attacked_by_tanker),
						tanker(TANKER_HP);
		
		get_attacked_by_boss -> TANKER_HP_NEW = TANKER_HP - 10,
								getAttackedBy(TANKER_HP_NEW, "Tanker", "Boss"), 
								
								%%calling archer
								io:format("~nTanker(~w): Calling Archer!", [TANKER_HP_NEW]), 
								Archer_Pid = global:whereis_name(archer_pid), 
								make_request(Archer_Pid, tanker_called),
								
								%%calling healer
								io:format("~nTanker(~w): Calling Healer to save my a$$!", [TANKER_HP_NEW]),
								Healer_Pid = global:whereis_name(healer_pid), 
								make_request(Healer_Pid, tanker_called),
								tanker(TANKER_HP_NEW);
		
		get_healed -> TANKER_HP_NEW = TANKER_HP + 10,
					  io:format("~nTanker(~w): Get healed by Healer!", [TANKER_HP_NEW]),   
					  Boss_Pid = global:whereis_name(boss_pid),
					  make_request(Boss_Pid, duel),  
					  tanker(TANKER_HP_NEW);
		
		duel -> TANKER_HP_NEW = TANKER_HP - 10, 
				io:format("~nTanker(~w): Attacking Boss again in a Duel!", [TANKER_HP_NEW]),  
				Boss_Pid = global:whereis_name(boss_pid),
				make_request(Boss_Pid, duel),   
				tanker(TANKER_HP_NEW) 
	end.		

boss(0) ->  
	Tanker_Pid = global:whereis_name(tanker_pid),
	make_request(Tanker_Pid, boss_dead), 
	io:format("~nBoss: I'm dead. Game Over!", []);
	
boss(BOSS_HP) -> 
	io:format("~nBoss(~w): wating", [BOSS_HP]),
	receive  
		tanker_dead ->  io:format("~nGame Over! Boss Won", []);
		
		get_attacked_by_tanker -> BOSS_HP_NEW = BOSS_HP - 10,
								  getAttackedBy(BOSS_HP_NEW, "Boss", "Tanker"), 
								  io:format("~nBoss(~w): Attacking back Tanker!", [BOSS_HP_NEW]),  
								  Tanker_Pid = global:whereis_name(tanker_pid),
								  make_request(Tanker_Pid, get_attacked_by_boss),
								  boss(BOSS_HP_NEW);
		
		get_attacked_by_archer -> BOSS_HP_NEW = BOSS_HP - 10,
								  getAttackedBy(BOSS_HP_NEW, "Boss", "Archer"),
								  io:format("~nBoss(~w): Attacking back Archer!", [BOSS_HP_NEW]),  
								  Archer_Pid = global:whereis_name(archer_pid), 
								  make_request(Archer_Pid, get_attacked_by_boss),
								  boss(BOSS_HP_NEW);
		
		archer_dead -> io:format("~nBoss(~w): Archer is dead LMAO attacking Healer", [BOSS_HP]),
					   Healer_Pid = global:whereis_name(healer_pid),  
					   make_request(Healer_Pid, get_attacked_by_boss),
					   boss(BOSS_HP);
		
		duel ->  BOSS_HP_NEW = BOSS_HP - 10, 
				 getAttackedBy(BOSS_HP_NEW, "Boss", "Tanker"),  
				 io:format("~nBoss(~w): Attacking back Tanker in a Duel!", [BOSS_HP_NEW]),   
				 Tanker_Pid = global:whereis_name(tanker_pid),
				 make_request(Tanker_Pid, duel), 
				 boss(BOSS_HP_NEW)
	end.

archer(0) -> Boss_Pid = global:whereis_name(boss_pid),
			 make_request(Boss_Pid, archer_dead);

archer(ARCHER_HP) ->  
	io:format("~nArcher(~w): wating", [ARCHER_HP]), 
	receive  
		tanker_called -> io:format("~nArcher(~w): Tanker called! Attacking Boss", [ARCHER_HP]),
						 Boss_Pid = global:whereis_name(boss_pid),
						 make_request(Boss_Pid, get_attacked_by_archer),
						 archer(ARCHER_HP);
		
		get_attacked_by_boss -> ARCHER_HP_NEW = ARCHER_HP - 10,
								getAttackedBy(ARCHER_HP_NEW, "Archer", "Boss"),
								archer(ARCHER_HP_NEW)
	end.

healer(0) -> getAttackedBy(0, "Healer", "Boss"),
			 Tanker_Pid = global:whereis_name(tanker_pid), 
			 make_request(Tanker_Pid, healer_dead);

healer(HEALER_HP) ->
	io:format("~nHealer(~w): wating", [HEALER_HP]),
	receive
		tanker_called -> io:format("~nHealer(~w): Tanker called! Healing Tanker", [HEALER_HP]), 
						 Tanker_Pid = global:whereis_name(tanker_pid),
						 make_request(Tanker_Pid, get_healed),
						 healer(HEALER_HP);
		
		get_attacked_by_boss -> HEALER_HP_NEW = HEALER_HP - 10,
								getAttackedBy(HEALER_HP_NEW, "Healer", "Boss")  
	end.


startTanker() ->    
	global:register_name(tanker_pid, spawn(fun() -> tanker(50) end)).

startGame() -> 
	global:register_name(game_pid, spawn(fun() -> game() end)).

startBoss() ->    
	global:register_name(boss_pid, spawn(fun() -> boss(60) end)).

startArcher() -> 
	global:register_name(archer_pid, spawn(fun() -> archer(10) end)).

startHealer() -> 
	global:register_name(healer_pid, spawn(fun() -> healer(10) end)).

start() ->   
	Game_Pid = global:whereis_name(game_pid),
	Tanker_Pid = global:whereis_name(tanker_pid),
	make_request(Game_Pid, {game_started, Tanker_Pid}).

