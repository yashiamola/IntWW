import random 

def nthSmallest(res, k, n): 
  
    # Sort the given array  
    res.sort() 
    # Remove duplicates from the array
    res = list( dict.fromkeys(res) )
  
    # Return nth element in the sorted array 
    print (res)
    return res[k-1] 
  
# Driver code 
if __name__=='__main__': 
    
    res = [] 
    num = 500
    start = 1
    end = 500

    # Randomly generate 500 numbers
    for j in range(num): 
        res.append(random.randint(start, end)) 
    
        
    print (res) 
  
    k = len(res) 
    #take input from the user
    user_input = input("Enter the value for n: ")
    n = int(user_input)
    
    print("nth smallest element is", 
          nthSmallest(res, n, k)) 
  



