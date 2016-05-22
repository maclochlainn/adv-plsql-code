/*
 * HelloWorld2.java
 * Chapter 1, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script test Java compilation.
 */

// Oracle class imports.
import oracle.jdbc.driver.*;

// Class definition.
public class HelloWorld2 {

  public static String hello() {
    return "Hello World."; }

  public static String hello(String name) {
    return "Hello " + name + "."; }

  public static void main(String args[]) {
    System.out.println(HelloWorld2.hello());
    System.out.println(HelloWorld2.hello("Larry")); }
}
