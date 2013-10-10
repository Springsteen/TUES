// Here I'm trying to program a simple terminal calculator.

#include <iostream>

using namespace std ;

	class Calculator {

		long int sum_ ;

	public :
		Calculator (long int sum) {
			sum_=sum ;
		}

		int getSum () {
			return sum_ ;
		}

		void clear () {
			sum_ = 0 ;
		}

		void addNum(int a) {
			sum_+=a ;
		}
		
		void subNum(int a) {
			sum_-=a ;
		}

		void divNum(int a) {
			sum_/=a ;
		}
	
		void multiNum(int a) {
			sum_*=a ;
		}
		
	} ;

	int main() {

		int choice ;
		long int number ;
		Calculator calc(0) ;

		for(;;) {
			cout << "\033[2J\033[1;1H" ;
			cout << "The current sum is :" << calc.getSum() << endl ;
			cout << "1 : +" << endl ;
			cout << "2 : -" << endl ;
			cout << "3 : *" << endl ;
			cout << "4 : /" << endl ;
			cout << "5 : CLEAR" << endl ;
			cout << "6 : EXIT" << endl ;
			cout << "Enter your choice :" << endl ;
			cin >>  choice ;

			switch (choice) {
				
				case 1 :
					cout << "Plese enter the number which you want to add :" << endl ;
					cin >> number ;
					calc.addNum(number) ;
					break ;
				case 2 :	
					cout << "Plese enter the number which you want to subtract :" << endl ;
					cin >> number ;
					calc.subNum(number) ;
					break ;
				case 3 :
					cout << "Plese enter the number which you want to multiple :" << endl ;
					cin >> number ;
					calc.multiNum(number) ;
					break ;
				case 4 :
					cout << "Plese enter the number which you want to divide :" << endl ;
					cin >> number ;
					calc.divNum(number) ;
					break ;
				case 5 :
					calc.clear() ;
					break ;
				case 6 :
					cout << "\033[2J\033[1;1H" ;
					return 0 ;
			}
		}

	}

