// Tested on Windows 10 and VSCode version 1.71.2

using System;
using static System.Console;
using System.Collections.Generic;
using System.IO;

namespace Assignment2
{
    class Program
    {
        static void Main(string[] args)
        {
            //a list of shapes
            LinkedList<Shape> shapes = new LinkedList<Shape>();
            string ans = "";
            int zIndex = 1; //zIndex
            string svg = "";
            //this is used for while loops
            bool cont = true;
            WriteLine("Here are the list of shapes and what number they are indexed on our system: \nRectangle = 01\nCircle = 02\nEllipse = 03\nLine = 04\nPolygon = 05\nPolyline = 06");
            while (cont)
            {
                Shape shape = new Shape();
                WriteLine(" ");
                //Get input from user
                WriteLine("Enter Shape number: ");
                string input = ReadLine();
                if (String.IsNullOrEmpty(input)) { cont = false; } //stop loop when user is finished
                else
                {
                    //user fills out appropriate information for various shapes
                    if (input == "01")
                    {
                        WriteLine(" ");
                        WriteLine("Set Parameters for Rectangle: ");
                        WriteLine("Position X: ");
                        int x = Convert.ToInt32(ReadLine());
                        WriteLine("Position Y: ");
                        int y = Convert.ToInt32(ReadLine());
                        WriteLine("Width of Rectangle: ");
                        int w = Convert.ToInt32(ReadLine());
                        WriteLine("Height of Rectangle: ");
                        int h = Convert.ToInt32(ReadLine());
                        shape.rectangle(input, x, y, w, h, zIndex++);
                        shapes.AddFirst(shape);
                    }
                    else if (input == "02")
                    {
                        WriteLine(" ");
                        WriteLine("Set Parameters for Circle: ");
                        WriteLine("Radius: ");
                        int r = Convert.ToInt32(ReadLine());
                        WriteLine("Position CX: ");
                        int x = Convert.ToInt32(ReadLine());
                        WriteLine("Position CY: ");
                        int y = Convert.ToInt32(ReadLine());
                        shape.circle(input, r, x, y, zIndex++);
                        shapes.AddFirst(shape);
                    }
                    else if (input == "03")
                    {
                        WriteLine(" ");
                        WriteLine("Set Parameters for Ellipse");
                        WriteLine("X radius of Ellipse: ");
                        int rx = Convert.ToInt32(ReadLine());
                        WriteLine("Y radius of Ellipse: ");
                        int ry = Convert.ToInt32(ReadLine());
                        WriteLine("Centre X of Ellipse: ");
                        int cx = Convert.ToInt32(ReadLine());
                        WriteLine("Centre Y of Ellipse: ");
                        int cy = Convert.ToInt32(ReadLine());
                        shape.ellipse(input, rx, ry, cx, cy, zIndex++);
                        shapes.AddFirst(shape);
                    }
                    else if (input == "04")
                    {
                        WriteLine(" ");
                        WriteLine("Set Parameters for Line");
                        WriteLine("X Co-ordinate for Point 1: ");
                        int x1 = Convert.ToInt32(ReadLine());
                        WriteLine("Y Co-ordinate for Point 1: ");
                        int y1 = Convert.ToInt32(ReadLine());
                        WriteLine("X Co-ordinate for Point 2: ");
                        int x2 = Convert.ToInt32(ReadLine());
                        WriteLine("Y Co-ordinate for Point 2: ");
                        int y2 = Convert.ToInt32(ReadLine());
                        shape.line(input, x1, y1, x2, y2, zIndex++);
                        shapes.AddFirst(shape);
                    }
                    else if (input == "05")
                    {
                        WriteLine(" ");
                        WriteLine("Set Parameters for Polygon");
                        WriteLine("Set the points for Polygon");
                        string coord = ReadLine();
                        shape.poly(input, coord, zIndex++);
                        shapes.AddFirst(shape);
                    }
                    else if (input == "06")
                    {
                        WriteLine(" ");
                        WriteLine("Set Paramters for Polyline");
                        WriteLine("Set the points for Polyline");
                        string coord = ReadLine();
                        shape.poly(input, coord, zIndex++);
                        shapes.AddFirst(shape);
                    }
                    else { WriteLine("Invalid Input \nTry Again"); }
                    WriteLine("Press Enter When Finished");
                }
                input = "";
            }
            Console.Clear();
            cont = true;
            WriteLine(" ");
            WriteLine("Your List of Shapes: ");
            foreach (Shape s in shapes) { s.getShape(); }
            WriteLine(" ");
            cont = true;
            //ask user if they would like to update or delete shapes in list
            WriteLine("Would you like to update or delete any shapes? \n(Answer with: yes/no)");
            ans = "";
            ans = ReadLine().ToLower();
            if (ans == "yes")
            {
                //create loop to continously ask user to update or delete shapes
                //stop loop if user is finished
                while (cont)
                {
                    WriteLine(" ");
                    WriteLine("Select Position: ");
                    foreach (Shape s in shapes) { s.getShape(); }
                    int index = Convert.ToInt32(ReadLine());
                    WriteLine(" ");
                    WriteLine("Please select Update or Delete: \n(Answer with: update/delete)");
                    string opp = ReadLine().ToLower();
                    if (opp == "delete") { deleteShape(shapes, index); }
                    else { updateList(shapes, index); }
                    svg = createSVG(shapes);
                    WriteLine(" ");
                    WriteLine("Would you like to continue to update or delete shapes? \nPress Enter if finished else or press any number and then Enter to continue");
                    if (String.IsNullOrEmpty(ReadLine())) { cont = false; }
                }
            }
            else
            {
                svg = createSVG(shapes);
            }
            Console.Clear();
            WriteLine(" ");
            //prints out SVG
            File.WriteAllText("shapes.svg", svg);
            WriteLine("Your SVG File: "+ svg + "Your SVG file is saved as shapes.svg");
        }
        //create SVG file method
        public static string createSVG(LinkedList<Shape> shape)
        {
            string beginning = "<svg width=\"300\" height=\"300\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">";
            string middle = "";
            string end = "</svg>";
            foreach (Shape s in shape)
            {
                if (s.getNum() == "01") { middle += "\n" + s.getRectangle(); }
                else if (s.getNum() == "02") { middle += "\n" + s.getCircle(); }
                else if (s.getNum() == "03") { middle += "\n" + s.getEllipse(); }
                else if (s.getNum() == "04") { middle += "\n" + s.getLine(); }
                else if (s.getNum() == "05") { middle += "\n" + s.getPolyline(); }
                else if (s.getNum() == "06") { middle += "\n" + s.getPolygon(); }
            }
            return beginning + middle + "\n" + end;
        }
        
        public static void updateList(LinkedList<Shape> shape, int index)
        {
            foreach (Shape s in shape)
            {
                if (index == s.getIndex())
                {
                    WriteLine("Current Value:");
                    if (s.getNum() == "01")
                    {
                        WriteLine("x value: " + s.getX1() + "\ny value: " + s.getY1() + "\nwidth value: " + s.getX2() + "\nheight value: " + s.getY2() + "\nstroke width value: " + s.getStokeWidth() + "\nfill value: " + s.getFill() + "\nstroke value: " + s.getStroke());
                        WriteLine(" ");
                        WriteLine("Enter New Values: ");
                        WriteLine("New x value: ");
                        s.setX1(Convert.ToInt32(ReadLine()));
                        WriteLine("New y value: ");
                        s.setY1(Convert.ToInt32(ReadLine()));
                        WriteLine("New width value: ");
                        s.setX2(Convert.ToInt32(ReadLine()));
                        WriteLine("New height value: ");
                        s.setY2(Convert.ToInt32(ReadLine()));
                        WriteLine("New stroke width value: ");
                        s.setStrokeWidth(Convert.ToInt32(ReadLine()));
                        WriteLine("New fill value (colour): ");
                        s.setFill(ReadLine());
                        WriteLine("New stroke value (colour): ");
                        s.setStroke(ReadLine());
                    }
                    else if (s.getNum() == "02")
                    {
                        WriteLine("cx value: " + s.getX1() + "\ncy value: " + s.getY1() + "\nradius value: " + s.getRadius() + "\nstroke width value: " + s.getStokeWidth() + "\nfill value: " + s.getFill() + "\nstroke value: " + s.getStroke());
                        WriteLine(" ");
                        WriteLine("Enter New Values: ");
                        WriteLine("New cx value: ");
                        s.setX1(Convert.ToInt32(ReadLine()));
                        WriteLine("New cy value: ");
                        s.setY1(Convert.ToInt32(ReadLine()));
                        WriteLine("New radius value: ");
                        s.setRad(Convert.ToInt32(ReadLine()));
                        WriteLine("New stroke width value: ");
                        s.setStrokeWidth(Convert.ToInt32(ReadLine()));
                        WriteLine("New fill value (colour): ");
                        s.setFill(ReadLine());
                        WriteLine("New stroke value (colour): ");
                        s.setStroke(ReadLine());
                    }
                    else if (s.getNum() == "03")
                    {
                        WriteLine("cx value: " + s.getX1() + "\ncy value: " + s.getY1() + "\nrx value: " + s.getX2() + "\nry value: " + s.getY2() + "\nstroke width value: " + s.getStokeWidth() + "\nfill value: " + s.getFill() + "\nstroke value: " + s.getStroke());
                        WriteLine(" ");
                        WriteLine("Enter New Values: ");
                        WriteLine("New cx value: ");
                        s.setX1(Convert.ToInt32(ReadLine()));
                        WriteLine("New cy value: ");
                        s.setY1(Convert.ToInt32(ReadLine()));
                        WriteLine("New rx value: ");
                        s.setX2(Convert.ToInt32(ReadLine()));
                        WriteLine("New ry value: ");
                        s.setY2(Convert.ToInt32(ReadLine()));
                        WriteLine("New stroke width value: ");
                        s.setStrokeWidth(Convert.ToInt32(ReadLine()));
                        WriteLine("New fill value (colour): ");
                        s.setFill(ReadLine());
                        WriteLine("New stroke value (colour): ");
                        s.setStroke(ReadLine());
                    }
                    else if (s.getNum() == "04")
                    {
                        WriteLine("x1 value: " + s.getX1() + "\ny1 value: " + s.getY1() + "\nx2 value: " + s.getX2() + "\ny2 value: " + s.getY2() + "\nstroke width value: " + s.getStokeWidth() + "\nfill value: " + s.getFill() + "\nstroke value: " + s.getStroke());
                        WriteLine(" ");
                        WriteLine("Enter New Values: ");
                        WriteLine("New x1 value: ");
                        s.setX1(Convert.ToInt32(ReadLine()));
                        WriteLine("New y1 value: ");
                        s.setY1(Convert.ToInt32(ReadLine()));
                        WriteLine("New x2 value: ");
                        s.setX2(Convert.ToInt32(ReadLine()));
                        WriteLine("New y2 value: ");
                        s.setY2(Convert.ToInt32(ReadLine()));
                        WriteLine("New stroke width value: ");
                        s.setStrokeWidth(Convert.ToInt32(ReadLine()));
                        WriteLine("New fill value (colour): ");
                        s.setFill(ReadLine());
                        WriteLine("New stroke value (colour): ");
                        s.setStroke(ReadLine());
                    }
                    else if (s.getNum() == "05")
                    {
                        WriteLine("points: " + s.getCoord() + "\nstroke width value: " + s.getStokeWidth() + "\nfill value: " + s.getFill() + "\nstroke value: " + s.getStroke());
                        WriteLine(" ");
                        WriteLine("Enter New Values: ");
                        WriteLine("New points: ");
                        s.setCoord(ReadLine());
                        WriteLine("New stroke width value: ");
                        s.setStrokeWidth(Convert.ToInt32(ReadLine()));
                        WriteLine("New fill value (colour): ");
                        s.setFill(ReadLine());
                        WriteLine("New stroke value (colour): ");
                        s.setStroke(ReadLine());
                    }
                    else if (s.getNum() == "06")
                    {
                        WriteLine("points: " + s.getCoord() + "\nstroke width value: " + s.getStokeWidth() + "\nfill value: " + s.getFill() + "\nstroke value: " + s.getStroke());
                        WriteLine(" ");
                        WriteLine("Enter New Values: ");
                        WriteLine("New points: ");
                        s.setCoord(ReadLine());
                        WriteLine("New stroke width value: ");
                        s.setStrokeWidth(Convert.ToInt32(ReadLine()));
                        WriteLine("New fill value (colour): ");
                        s.setFill(ReadLine());
                        WriteLine("New stroke value (colour): ");
                        s.setStroke(ReadLine());
                    }
                }
            }   
        }
        public static void deleteShape(LinkedList<Shape> shape, int index)
        {
            Shape temp = new Shape();
            foreach (Shape s in shape)
            {
                if (index == s.getIndex()) { temp = s; }
            }
            shape.Remove(temp);
        }
    }

    //creating classes and method for shapes
    class Shape
    {
        //shape class variables
        private string num;
        private int index;
        private int x1; 
        private int y1; 
        private int x2; 
        private int y2; 
        private int radius;
        private string coord;
        private string stroke;
        private int strokeWidth;
        private string fill;
        //shape methods
        public void rectangle(string num, int x, int y, int w, int h, int i)
        {
            this.num = num;
            this.index = i;
            this.x1 = x;
            this.y1 = y;
            this.x2 = w;
            this.y2 = h;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "red";
        }
        public void circle(string num, int r, int x, int y, int i)
        {
            this.num = num;
            this.index = i;
            this.x1 = x;
            this.y1 = y;
            this.radius = r;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "red";
        }
        public void ellipse(string num, int rx, int ry, int cx, int cy, int i)
        {
            this.num = num;
            this.index = i;
            this.x1 = rx;
            this.y1 = ry;
            this.x2 = cx;
            this.y2 = cy;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "red";
        }
        public void line(string num, int x1, int y1, int x2, int y2, int i)
        {
            this.num = num;
            this.index = i;
            this.x1 = x1;
            this.y1 = y1;
            this.x2 = x2;
            this.y2 = y2;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "red";
        }
        public void poly(string num, string s, int i)
        {
            this.num = num;
            this.index = i;
            this.coord = s;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "red";
        }
        //print out z index and shape
        public void getShape()
        {
            WriteLine("Position: " + this.index + ", Num: " + this.num);
        }

        //getters and setters
        public void setNum(String n) { this.num = n; }
        public void setIndex(int i) { this.index = i; }
        public void setX1(int x) { this.x1 = x; }
        public void setY1(int y) { this.y1 = y; }
        public void setX2(int x) { this.x2 = x; }
        public void setY2(int y) { this.y2 = y; }
        public void setRad(int r) { this.radius = r; }
        public void setCoord(string s) { this.coord = s; }
        public void setStrokeWidth(int w) { this.strokeWidth = w; }
        public void setFill(string f) { this.fill = f; }
        public void setStroke(string s) { this.stroke = s; }
        public string getNum() { return this.num; }
        public int getIndex() { return this.index; }
        public int getX1() { return this.x1; }
        public int getY1() { return this.y1; }
        public int getX2() { return this.x2; }
        public int getY2() { return this.y2; }
        public int getRadius() { return this.radius; }
        public string getCoord() { return this.coord; }
        public string getFill() { return this.fill; }
        public string getStroke() { return this.stroke; }
        public int getStokeWidth() { return this.strokeWidth; }

        //method allows to fill in appropriate line for SVG file
        public string getRectangle()
        {
            return "    <rect x=\"" + this.x1 + "\" y=\"" + this.y1 + "\" width=\"" + this.x2 + "\" height=\"" + this.y2 + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
        public string getCircle()
        {
            return "    <circle cx=\"" + this.x1 + "\" cy=\"" + this.y1 + "\" r=\"" + this.radius + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
        public string getEllipse()
        {
            return "    <ellipse cx=\"" + this.x1 + "\" cy=\"" + this.y1 + "\" rx=\"" + this.x2 + "\" ry=\"" + this.y2 + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
        public string getLine()
        {
            return "    <line x1=\"" + this.x1 + "\" y1=\"" + this.y1 + "\" x2=\"" + this.x2 + "\" y2=\"" + this.y2 + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
        public string getPolygon()
        {
            return "    <polygon fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" points=\"" + this.coord + "\"/>";
        }
        public string getPolyline()
        {
            return "    <polyline fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" points=\"" + this.coord + "\"/>";
        }
    }
}
