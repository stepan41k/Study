package src;

import java.util.ArrayList;
import java.util.List;

public class Human {
    private int age;
    private String firstName;
    private String lastName;
    private List<String> relatives;
    
    public Human(int age, String firstName, String lastName) {
        this.age = age;
        this.firstName = firstName;
        this.lastName = lastName;
    }
    
    public int getAge() {
        return age;
    }
    
    public String getFirstName() {
        return firstName;
    }
    public String getLastName() {
        return lastName;
    }
    
    public void setRelatives(List<String> relatives) {
        this.relatives = relatives;
    }
    
    public List<String> getRelatives() {
        return relatives;
    }
}