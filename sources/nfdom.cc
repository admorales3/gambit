//#
//# FILE: nfdom.cc -- Compute dominated strategies on normal form
//#
//# @(#)nfdom.cc	1.9 9/1/96
//#

#include "nfg.h"
#include "nfstrat.h"
#include "nfgciter.h"
#include "rational.h"
#include "gstatus.h"

bool Dominates(const NFSupport &S, int pl, int a, int b, bool strong)
{
  const BaseNfg &N = S.BelongsTo();

  switch (N.Type())   {
    case DOUBLE:  {
      NfgContIter<double> A(&S), B(&S);

      A.Freeze(pl);
      A.Set(pl, a);
      B.Freeze(pl);
      B.Set(pl, b);
  
      if (strong)  {
	do  {
	  double ap = A.Payoff(pl);
	  double bp = B.Payoff(pl);
	  if (ap <= bp)  return false;
	  A.NextContingency();
	} while (B.NextContingency());
	
	return true;
      }

		bool equal = true;
      
      do   {
	double ap = A.Payoff(pl);
	double bp = B.Payoff(pl);
	if (ap < bp)   return false;
	else if (ap > bp)  equal = false;
	A.NextContingency();
      } while (B.NextContingency());

		return (!equal);
    }

    case RATIONAL:  {
      NfgContIter<gRational> A(&S), B(&S);

      A.Freeze(pl);
      A.Set(pl, a);
		B.Freeze(pl);
      B.Set(pl, b);
  
      if (strong)  {
	do  {
	  gRational ap = A.Payoff(pl);
	  gRational bp = B.Payoff(pl);
	  if (ap <= bp)  return false;
	  A.NextContingency();
	} while (B.NextContingency());
	
	return true;
      }

      bool equal = true;
      
      do   {
	gRational ap = A.Payoff(pl);
	gRational bp = B.Payoff(pl);
	if (ap < bp)   return false;
	else if (ap > bp)  equal = false;
	A.NextContingency();
      } while (B.NextContingency());
      
      return (!equal);
    }
    default:
		assert(0);
      return false;
  }
}


NFStrategySet *ComputeDominated(NFSupport &S, int pl, bool strong,
				gOutput &tracefile, gStatus &status)
{
  NFStrategySet *SS = S.GetNFStrategySet(pl);

  gArray<int> set(SS->NumStrats());
  int i;
  for (i = 1; i <= set.Length(); i++)
	 set[i] = i;

  int min, dis;
  double d1,d2;
  d1 = (double)(pl-1)/(double)S.BelongsTo().NumPlayers();
  d2 = (double)pl/(double)S.BelongsTo().NumPlayers();
  for (min = 0, dis = SS->NumStrats() - 1; min <= dis && !status.Get(); )  {
	 int pp;
	 double s1 = (double)min/(double)(dis+1);
	 status.SetProgress((1.0-s1)*d1 + s1*d2);
	 for (pp = 0;
	 pp < min && !Dominates(S, pl, set[pp+1], set[dis+1], strong);
	 pp++);
	 if (pp < min)
		dis--;
	 else  {
		int foo = set[dis+1];
		set[dis+1] = set[min+1];
		set[min+1] = foo;

		for (int inc = min + 1; inc <= dis; )  {
	if (Dominates(S, pl, set[min+1], set[dis+1], strong))  {
			 tracefile << SS->GetStrategy(set[dis+1])->number << " dominated by " << SS->GetStrategy(set[min+1])->number << '\n';
	  dis--;
	}
	else if (Dominates(S, pl, set[dis+1], set[min+1], strong))  {
	  tracefile << SS->GetStrategy(set[min+1])->number << " dominated by " << SS->GetStrategy(set[dis+1])->number << '\n';
	  foo = set[dis+1];
	  set[dis+1] = set[min+1];
	  set[min+1] = foo;
	  dis--;
	}
	else  {
	  foo = set[dis+1];
	  set[dis+1] = set[inc+1];
	  set[inc+1] = foo;
	  inc++;
	}
		}
		min++;
	 }
  }


  if (min + 1 <= SS->NumStrats())   {
	 NFStrategySet *T = new NFStrategySet(*SS);
	 for (i = min + 1; i <= SS->NumStrats(); i++)
		T->RemoveStrategy(SS->GetStrategy(set[i]));

	 return T;
  }
  else
    return 0;
}


NFSupport *ComputeDominated(NFSupport &S, bool strong,
				 const gArray<int> &players,
				 gOutput &tracefile, gStatus &status=gstatus)
{
  NFSupport *T = new NFSupport(S);
  bool any = false;

  for (int i = 1; i <= players.Length() && !status.Get(); i++)   {
	 int pl = players[i];
	 tracefile << "Dominated strategies for player " << pl << ":\n";
	 NFStrategySet *SS = ComputeDominated(S, pl, strong, tracefile,status);
// status.SetProgress((double)i/players.Length());

    if (SS)   {
      delete T->GetNFStrategySet(pl);
      T->SetNFStrategySet(pl, SS);
      any = true;
    }
  }

  if (!any || status.Get())  {
    delete T;
    return 0;
  }
  return T;
}
