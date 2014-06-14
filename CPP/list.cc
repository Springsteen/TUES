#include <iostream>
using namespace std;

template<typename T> 
class List {
	struct Node {
		T data_;
		
		Node* prev_;
		Node* next_;

		Node(T val){
			data_=val;
		}	

	};

	Node* head_;

public:

	List()
	:head_(new Node(1))
	{	
		head_->next_ = head_->prev_ = head_;
	}

	~List() {
		while(!empty())
			pop_front();
	}

	List(List& l2)
	:head_(new Node(0))
	{
		head_->next_ = head_->prev_ = head_;
		Node* curr = l2.head_->prev_;
		do {
			push_front(curr->data_);
			curr = curr->prev_;
		}while(curr != l2.head_);
	}

	bool empty() {
		return head_->next_ == head_;
	}

	void push_back(T val) {
		Node* new_elem = new Node(val);
		Node* tmp = head_->prev_;

		new_elem->next_ = head_;
		new_elem->prev_ = tmp;

		tmp->next_ = new_elem;
		head_->prev_ = new_elem;
	}

	void push_front(T val) {
		Node* new_elem = new Node(val);
		Node* tmp = head_->next_;

		new_elem->next_ = tmp;
		new_elem->prev_ = head_;

		tmp->prev_ = new_elem;
		head_->next_ = new_elem;
	}

	T pop_back() {
		Node* wanted = head_->prev_;
		T for_return = wanted->data_; 
		
		Node* new_prev = wanted->prev_;

		head_->prev_ = new_prev;
		new_prev->next_ = head_;

		delete wanted;

		return for_return;
	}

	T pop_front() {
		Node* wanted = head_->next_;
		T for_return = wanted->data_;

		Node* new_next = wanted->next_;

		head_->next_ = new_next;
		new_next->prev_ = head_;

		delete wanted;

		return for_return;
	}

	T& back() {
		return head_->prev_->data_;
	}

	T& front() {
		return head_->next_->data_;
	}

	void operator=(List& other){
		while(!empty())
			pop_back();

		Node* curr = other.head_->prev_;
		do {
			push_front(curr->data_);
			curr = curr->prev_;
		}while(curr != other.head_);
	}

};

int main(){
	
	List<int> l2;

	cout << "l2 empty:" << l2.empty() << endl;

	l2.push_back(1);
	l2.push_back(2);
	l2.push_back(3);

	List<int> l1;

	for (int i = 0; i < 10; ++i){
		l1.push_back(i);
	}

	l1 = l2;

	cout << "l1 empty:" << l1.empty() << endl;	

	while(!l1.empty()){
		cout << l1.pop_back() << endl;
	}

	return 0;
}
