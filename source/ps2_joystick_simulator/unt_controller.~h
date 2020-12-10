//---------------------------------------------------------------------------

#ifndef unt_controllerH
#define unt_controllerH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// Von der IDE verwaltete Komponenten
	TBevel *Bevel1;
	TShape *Shape2;
	TLabel *Label1;
	TLabel *Label2;
	TLabel *Label3;
	TLabel *Label4;
	TMemo *Memo1;
	void __fastcall FormDestroy(TObject *Sender);
	void __fastcall Shape2MouseMove(TObject *Sender, TShiftState Shift, int X,
          int Y);
private:	// Anwender-Deklarationen

		TShape *left[25];
		int x;
      int y;

		int max;
		int RJoyX;
		int RJoyY;
		int LJoyX;
		int LJoyY;
		int rest;
		int Pos;

		String rx;
		String ry;
		String lx;
		String ly;

public:		// Anwender-Deklarationen
	__fastcall TForm1(TComponent* Owner);
	String __fastcall IntToBin(int dezimal, String bin)
	{
		int rest=0;
		int Pos = dezimal;
		bin = "00000000";
		for(int i=bin.Length();i>0;i--)
		{
			rest = Pos%2;
			Pos=Pos/2;
			if(rest==0)
			{
				bin[i]='0';
			}
			else
			{
				bin[i]='1';
			}
		}
		return bin;
	}
	String __fastcall IntToBin2(int dezimal)
	{
		int rest=0;
		int Pos = dezimal;
		String bin = "00000000";
		for(int i=bin.Length();i>0;i--)
		{
			rest = Pos%2;
			Pos=Pos/2;
			if(rest==0)
			{
				bin[i]='0';
			}
			else
			{
				bin[i]='1';
			}
		}
		return bin;
	}
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
