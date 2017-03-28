
% On calcule les fils du leader dans une fonction à part
calculArbreLeader(Voisins,Leader) ->
    MessagePere = {pere,self()},
    Taille=length(Voisins),
    % On envoie à tous nos voisins qu'on est le père
    envoiListe(Voisins,MessagePere),
    % On attend que tous nos fils se soient bien activés
    receptionFilsLeader(Taille),
    % Comme on est le leader, tous nos voisins sont nos fils
    Fils=Voisins,
    % On attend que tous nos fils soient désactivés
    attenteDesactivationLeader(Taille),
    % Puis on sait qu'on a finit la construction de l'arbre
    finConstructionArbre().

% Fin de la construction de l'arbre
finConstructionArbre()->
    ok

% Si tous les fils du leader se sont désactivés c'est bon
attenteDesactivationLeader(Taille) when Taille == 0 ->
    ok.

% Tant que tous les fils du leader ne se sont pas désactivés on attend
attenteDesactivationLeader(Taille) when Taille > 0 ->
    receive
	{fils,desactive,FilsUid} ->
	    attenteDesactivationLeader(Taille-1);
	X -> io:write(X)
    end.

% Quand il n'y a plus de voisins c'est bon
envoiListe([],_) ->
    ok;
% Tant qu'on a des voisins ont leur fait une demande de parenté
envoiListe([Fils|Voisins],MessagePere) ->
    Fils ! MessagePere,
    envoiListe(Voisins,MessagePere).

% Tous les fils du leader se sont activés
receptionFilsLeader(Taille) when Taille == 0 ->
    ok;
% le leader attend que tous les fils du leader s'active
receptionFilsLeader(Taille) when Taille > 0 ->
    receive
	{fils,ok,FilsUid} ->
	    receptionFils(Taille-1);
	X ->io:write(X)
    end.

% Benoît
activation(Pere) ->
    ok.

% Tous nos fils sont désactivés, on ne répond qu'aux processus qui veulent être nos père avec une réponse négative, et on attend de se faire activer pour continuer
desactive(Pere) ->
    receive
	{pere,PereUid} ->
	    PereUid ! {fils,nop,self()},
	    desactive(Pere);
	{activation} -> activation(Pere);
	X ->io:write(X)
    end.

% Si on connaît tous nos fils et qu'ils sont tous désactivés, on envoie un message à notre père pour dire qu'on se désactive, puis on se désactive
receptionfilsGeneral(Fils,Taille,FilsDesactives,Pere) when Taille == 0 and length(Fils) == FilsDesactives ->
    Pere ! {fils,desactive,self()},
    desactive(Pere);

%On connaît tous nos fils, mais ils ne sont pas tous désactivés
receptionFilsGeneral(Fils,Taille,FilsDesactives,Pere) when Taille == 0 ->
    receive
	{fils,desactive,IdFils} ->
	    f2(Fils,Taille,FilsDesactives+1,Pere);
	{pere,PereUid} ->
	    PereUid ! {fils,nop,self()},
	    f2(Fils,Taille,FilsDesactives,Pere);
	X ->io:write(X)
    end;

% Tant que Taille est supérieur à 0, c'est qu'on n'a pas encore reçu de réponse de tous nos voisins, et qu'on ne sait donc pas encore qui sont nos fils
receptionFilsGeneral(Fils,Taille,FilsDesactives,Pere) when Taille > 0 ->
    receive
	% Si on reçoit un refus de parenté, on décrémente Taille
	{fils,nop,IdFils} ->
	    f2(Fils,Taille-1,FilsDesactives,Pere);
	% Si on reçoit une acceptation de parenté, on décrémente Taille et on ajoute Fils à la liste des fils
	{fils,ok,IdFils} ->
	    f2([IdFils|Fils],Taille-1,FilsDesactives,Pere);
	% Si on reçoit une demande de parenté, on la refuse
	{pere,PereUid} ->
	    PereUid ! {fils,nop,self()},
	    f2(Fils,Taille,FilsDesactives,Pere);
	% Si on reçoit une désactivation d'un de nos fils, on s'en souvient en incrémentant le nombre de fils désactivés
	{fils,desactive,IdFils} ->
	    f2(Fils,Taille,FilsDesactives+1,Pere);
	X ->io:write(X)
    end.

% La création de l'arbre pour tous les processus qui ne sont pas le leader
calculArbreGeneral(Voisins,Leader) ->
    MessagePere = {pere,self()},
    receive
	% Activation de notre processus via le message du père
	{pere,PereUid} ->
	    % On lui envoie une confirmation de parenté
	    PereUid ! {fils,ok,self()},
	    % On supprime notre père de notre liste de fils potentiels
	    VoisinsSansPere=lists:delete(PereUid,Voisins),
	    % On envoie à tous nos fils potentiels une demande de parenté
	    envoiListe(VoisinsSansPere,MessagePere),
	    Taille=length(VoisinsSansPere),
	    % On attend la réponse de nos voisins (excepté le père)
	    receptionFilsGeneral([],Taille,0,PereUid);
	X ->io:write(X)
    end.