#include <iostream>

using namespace std;

template<typename T> 
class Vector {

	int capacity_;
	int size_;
	T* buffer_;

	void resize(int chunk) {
		if( size_ + chunk < capacity_)
			return;

		T* old = buffer_;

		capacity_+=chunk;
		buffer_ = new T[capacity_];

		for(int i=0; i<size_; i++) {
			buffer_[i] = old[i];
		}

		delete [] old;
	}

public:

	Vector(int capacity)
	:capacity_(capacity),
	 size_(0),
	 buffer_(new T[capacity_])
	{}

	Vector(Vector& other)
	:capacity_(other.capacity()),
	 size_(other.size()),
	 buffer_(new T[capacity_])
	{
		for (int i = 0; i < capacity_; ++i){
			buffer_[i] = other.buffer_[i];
		}
	}

	~Vector(){
		delete [] buffer_;
	}

	bool empty(){
		return size_ == 0;
	}

	int size(){
		return size_;
	}

	int capacity(){
		return capacity_;
	}

	void push_back(T val){

		if (size_ == capacity_)
			resize(1);

		buffer_[size_++] = val;
	}

	T pop_back(){
		return buffer_[--size_];
	}

	Vector& operator=(Vector& other){
		if(this != &other){
			delete [] buffer_;
			capacity_ = other.capacity_;
			size_ = other.size_;
			buffer_ = new T[size_];

			for(int i = 0; i < size_; i++){
				buffer_[i] = other.buffer_[i];
			}
		}

		return *this;
	}

};

int main(){
		
	Vector<int> v(5);

	for(int i=0; i<10; i++) {
		v.push_back(i);
	}

	Vector<int> v2 = v;

	while(!v2.empty()) {
		cout << v2.pop_back() << endl;
	}
 
	return 0;
}

