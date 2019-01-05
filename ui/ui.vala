using Gtk;
using Gdk;
using Pango;
using Gee;
using Json;

static AppWin app;
static MyGrid grid1;
static LoginDialog login1;
static RpcClient rpc1;
static AddUserDialog adduser1;

public struct UserData {
	public int64 id;
	public int16 sex;
	public string name;
	public string desc;
	public int16 age;
	public string msg_offline;
	public string timestamp_offline;
}
public class MyGrid: GLib.Object{
	Gtk.ListBox friends;
	Gtk.ListBox msgs = null;
	Gtk.Entry entry1;
	public Gtk.Entry port1;
	int64 to;
	bool running = true;
	//public MyBrowser browser;

	public Gtk.Grid mygrid;
	Gee.HashMap<string,UserData?> frds1;
	Gee.HashMap<string,weak Gtk.Grid?> frd_boxes;
	public Gtk.CssProvider provider1;
	public Gtk.CssProvider mark1;
	public Gtk.CssProvider button1;
	public Gtk.CssProvider link_css1;
	public Gtk.Button strangers_btn;
	public Gtk.Button user_btn;

	public string man_icon = "icons/man.png";
	public string woman_icon = "icons/woman.png";
	public int64 uid;
	public int16 usex;
	public string uname;
	public string udesc;
	public int16 uage;
	Gtk.CssProvider cssp;
	Gtk.ScrolledWindow msg_win;
	public MyGrid(){
		//this.browser = new MyBrowser();
		this.frds1 = new Gee.HashMap<string,UserData?>();
		this.frd_boxes = new Gee.HashMap<string,weak Gtk.Grid?>();
		this.mygrid = new Gtk.Grid();
		this.mygrid.set_column_spacing(5);
		this.cssp = new Gtk.CssProvider();
		var sc = this.mygrid.get_style_context ();
		sc.add_provider(this.cssp,Gtk.STYLE_PROVIDER_PRIORITY_USER);
		this.cssp.load_from_data("""grid{
	padding:5px 5px 5px 5px;
	background-color:#BABABA;
}
list{
	background-color:#FFFFFF;
	color:#000000;
}
""");

		this.provider1 = new Gtk.CssProvider();
		this.provider1.load_from_data("""grid{color:#FF0000;}
""");

		this.mark1 = new Gtk.CssProvider();
		this.mark1.load_from_data("""grid{color:#0000FF;}
""");

		this.button1 = new Gtk.CssProvider();
		this.button1.load_from_data("""button{color:#FF0000;}
""");
		this.link_css1 = new Gtk.CssProvider();
		this.link_css1.load_from_data("label>link{color:#0000FF;}");

		var scrollWin1 = new Gtk.ScrolledWindow(null,null);
		scrollWin1.width_request = 160;
		scrollWin1.expand = true;
		this.mygrid.attach(scrollWin1,0,0,2,3);
		this.friends = new Gtk.ListBox();
		scrollWin1.add(this.friends);
		var t1 = new Gtk.Label("我的朋友");
		this.friends.add(t1);
		var r0 = (t1.parent as Gtk.ListBoxRow);
		r0.set_selectable(false);
		r0.name = "0";
		this.friends.border_width = 3;
		var sc1 = this.friends.get_style_context ();
		sc1.add_provider(this.cssp,Gtk.STYLE_PROVIDER_PRIORITY_USER);

		this.friends.set_sort_func((row1,row2)=>{
			if(row1.name=="0"){
				return -1;
			}
			var rsc1 = this.frd_boxes[row1.name].get_style_context();
			var rsc2 = this.frd_boxes[row2.name].get_style_context();
			if(rsc1.has_class("off")){
				if(rsc2.has_class("off")){
					if(row1.name.to_int64() > row2.name.to_int64()){
						return 1;
					}else{
						return -1;
					}
				}else{
					//print("row1 is off row2 on\\n");
					return 1;
				}
			}else{
				if(rsc2.has_class("off")){
					//print("row1 is on row2 off\n");
					return -1;
				}else if(row1.name.to_int64() > row2.name.to_int64()){
					return 1;
				}else{
					return -1;
				}
			}
		});

		var b1 = new Gtk.Button.with_label("找人");
		this.mygrid.attach(b1,0,3,1,1);

		strangers_btn = new Gtk.Button.with_label("陌生人");
		this.mygrid.attach(strangers_btn,1,3,1,1);

		user_btn = new Gtk.Button.with_label("登录用户");
		this.mygrid.attach(user_btn,2,0,1,1);
		user_btn.hexpand = true;

		var sp = new Gtk.Image();
		sp.hexpand = true;
		this.mygrid.attach(sp,3,0,1,1);

		var b4 = new Gtk.Label("代理端口");
		b4.hexpand = true;
		this.mygrid.attach(b4,4,0,1,1);

		port1 = new Gtk.Entry();
		port1.set_text(proxy_port.to_string());
		port1.max_length = 5;
		port1.width_request = 50;
		port1.editable=false;
		this.mygrid.attach(port1,5,0,1,1);

		var b6 = new Gtk.Button.with_label("修改");
		this.mygrid.attach(b6,6,0,1,1);

		this.msg_win = new Gtk.ScrolledWindow(null,null);
		this.msg_win.height_request = 450;
		this.msg_win.expand = true;
		this.mygrid.attach(this.msg_win,2,1,5,1);

		var grid1 = new Gtk.Grid();
		this.mygrid.attach(grid1,2,2,5,2);

		var bf1  = new Gtk.Button.with_label("文件");
		grid1.attach(bf1,0,0,1,1);

		var bp1  = new Gtk.Button.with_label("图片");
		grid1.attach(bp1,1,0,1,1);

		this.entry1 = new Gtk.Entry();
		grid1.attach(this.entry1,0,1,3,1);
		this.entry1.hexpand = true;

		var b7 = new Gtk.Button.with_label("发送");
		grid1.attach(b7,3,1,1,1);

		this.mygrid.show.connect(()=>{
			//var mutex1 = new GLib.Mutex();
			var thread = new GLib.Thread<bool>("tell",()=>{
				var ids = this.frds1.keys;
				foreach( string k1 in ids){
					//mutex1.lock();
					print("%s\n",k1);
					if(k1 == this.uid.to_string())
						continue;
					GLib.Idle.add(()=>{
						if( rpc1.tell(k1.to_int64())==false ){
							Gtk.main_quit();
						}
						//mutex1.unlock();
						return false;
					});
				}
				return true;
			});
			strangers1 = new StrangersDialg();
			uint16 port2;
			if(rpc1.get_proxy(out port2)){
				proxy_port = port2;
				this.port1.text = proxy_port.to_string();
			}else{
				Gtk.main_quit();
			}
		});

		bf1.clicked.connect(()=>{
			if(this.to==0 || this.to==this.uid)
				return;
			//file choose
			Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
				"Select your favorite file", app, Gtk.FileChooserAction.OPEN,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Open",
				Gtk.ResponseType.ACCEPT);
			// Multiple files can be selected:
			chooser.select_multiple = false;
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var uri = chooser.get_uri ();
				//print ("Selection: %s\n",uri);
				if (uri[0:7]=="file://"){
					//print ("Selection: %s\n",uri[7:uri.length]);
					var fname = GLib.Filename.from_uri(uri);
					if( rpc1.send_file(this.to, fname) ){
						string text1 = @"<a href='$(uri)'>$(GLib.Path.get_basename(fname))</a>";
						this.add_left_name_icon(this.uname,this.usex);
						this.add_text(text1,true,true);
					}else{
						Gtk.main_quit();
					}
				}
			}
			chooser.close();
		});

		bp1.clicked.connect(()=>{
			if(this.to==0 || this.to==this.uid)
				return;
			//file choose
			Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
				"Select your favorite file", app, Gtk.FileChooserAction.OPEN,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Open",
				Gtk.ResponseType.ACCEPT);
			// Multiple files can be selected:
			chooser.select_multiple = false;
			Gtk.FileFilter filter = new Gtk.FileFilter ();
			chooser.set_filter (filter);
			filter.add_mime_type ("image/*");
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var uri = chooser.get_uri ();
				//print ("Selection: %s\n",uri);
				if (uri[0:7]=="file://"){
					//print ("Selection: %s\n",uri[7:uri.length]);
					var fname = GLib.Filename.from_uri(uri);
					if( rpc1.send_file(this.to, fname) ){
						string text1 = @"<a href='$(uri)'>$(GLib.Path.get_basename(fname))</a>";
						this.add_left_name_icon(this.uname,this.usex);
						this.add_text(text1,true,true);
					}else{
						Gtk.main_quit();
					}
				}
			}
			chooser.close();
		});

		b1.clicked.connect(()=>{
			search1 = new SearchDialg();
			search1.show();
			return;
		});

		b6.clicked.connect (() => {
			// 修改代理端口
			if(port1.editable==false){
				port1.editable = true;
				b6.set_label("保存");
			}else{
				port1.editable=false;
				b6.set_label("修改");
				var ret = rpc1.set_proxy( (uint16)port1.text.to_int64() );
				if(ret==false)
					Gtk.main_quit();
			}
		});
        strangers_btn.clicked.connect (() => {
			strangers1.show();
		});
        user_btn.clicked.connect (() => {
			// Emitted when the button has been activated:
			var dlg_user = new Gtk.MessageDialog(app, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK,null);
			dlg_user.text = @"登录用户：$(this.uname) 的情况";
			var sex="男";
			if (this.usex==2)
				sex="女";
            dlg_user.secondary_text = @"ID:$(this.uid)\n年龄：$(this.uage)\n性别：$(sex)\n自述：$(this.udesc)";
            dlg_user.show();
            dlg_user.response.connect((rid)=>{
				dlg_user.destroy();
			});
		});
        b7.clicked.connect (() => {
			// 发送信息
			if(this.to>0)
				if( false == rpc1.ChatTo(this.to,this.entry1.text) ){
					Gtk.main_quit();
				}
				//var u = this.frds1[this.uid.to_string()];
				this.add_left_name_icon(this.uname,this.usex);
				this.add_text(this.entry1.text);
				this.entry1.text = "";
				GLib.Idle.add(()=>{
					var adj1 = this.msgs.get_adjustment();
					adj1.value = adj1.upper;
					return false;
				});
		});

		this.friends.row_selected.connect((r)=>{
			var id = r.name.to_int64();
			if (id==0)
				return;
			this.to = id;
			var u = this.frds1[id.to_string()];
			//stdout.printf(@"selected $(id) $(u.name) $(u.sex)\n");
			if (this.msgs!=null){
				this.msg_win.remove(this.msgs);
			}
			this.msgs = this.boxes[id.to_string()];
			this.msg_win.add(this.msgs);
			Gtk.Grid grid = this.frd_boxes[id.to_string()];
			var sc3 = grid.get_style_context();
			sc3.remove_provider(this.mark1);
			sc3.remove_class("mark");
			//test css
			/*
			Gtk.Grid grid = this.frd_boxes[id.to_string()];
			var sc3 = grid.get_style_context();
			sc3.remove_provider(this.provider1);
			* */
			this.msg_win.show_all();
		});
	}
	Gee.HashMap<string,Gtk.ListBox?> boxes = new Gee.HashMap<string,Gtk.ListBox?>();
	//Gtk.ListBox hides = new Gtk.ListBox();
	public void add_listbox_id(int64 uid){
		var box = new Gtk.ListBox();
		this.boxes[uid.to_string()] = box;
		box.selection_mode = Gtk.SelectionMode.NONE;
		box.expand = true;
		box.border_width = 3;
		//this.msgs.modify_bg(Gtk.StateType.NORMAL,color1);
		//this.msg_win.add(box);
		var u1 = this.frds1[uid.to_string()];
		var t2 = new Gtk.Label(@"和 $(u1.name) 聊天");
		box.add(t2);
		(t2.parent as Gtk.ListBoxRow).set_selectable(false);

		if (this.msgs!=null){
			this.msg_win.remove(this.msgs);
		}
		this.msgs = box;
		this.msg_win.add(this.msgs);
		this.to = uid;
		if (u1.timestamp_offline.length > 10){
			//insert offline message
			add_right_name_icon(u1.name,u1.sex);
			add_text(@"离线信息：[$(u1.timestamp_offline)]\n$(u1.msg_offline)");
		}
		this.msg_win.show_all();

		var sc2 = box.get_style_context ();
		sc2.add_provider(this.cssp,Gtk.STYLE_PROVIDER_PRIORITY_USER);
	}

	public void release_resource(){
		this.running = false;
		//this.conn.close();
	}
	string pressed = "";
	public void add_friend(UserData user1){
		if(this.frds1.has_key(user1.id.to_string()))
			return;
		else
			this.frds1[user1.id.to_string()] = user1;
		if( false==rpc1.tell(user1.id) ){
			Gtk.main_quit();
		}
		string iconp;
		if (user1.sex==1)
			iconp = this.man_icon;
		else
			iconp = this.woman_icon;
		var pix1 = new Gdk.Pixbuf.from_file(iconp);
        var grid2 = new Gtk.Grid();
        var img2 = new Gtk.Image();
        img2.set_from_pixbuf(pix1);
        grid2.attach(img2,0,0);

        var l2 = new Gtk.Label(user1.name);
		l2.xalign = (float)0;
		l2.hexpand = true;
        grid2.attach(l2,1,0);

        var b2 = new Gtk.Button.with_label("WEB");
        grid2.attach(b2,2,0);
        grid2.set_column_spacing(5);

        this.frd_boxes[@"$(user1.id)"] = grid2;
        this.friends.add(grid2);
        //var row2 = new Gtk.ListBoxRow();
        //row2.add(grid2);
        var row2 = grid2.get_parent() as Gtk.ListBoxRow;
        row2.name = @"$(user1.id)";
        //this.friends.add(row2);
        //grid2.parent.name = @"$(user1.id)";
        grid2.show_all();

        img2.tooltip_text = @"$(user1.age)岁\n$(user1.desc)";

        b2.clicked.connect(()=>{
			//stdout.printf(@"open %$(uint64.FORMAT)\n",user1.id);
			if( false == rpc1.set_http_id(user1.id) ){
				Gtk.main_quit();
			}
		});
		this.friends.button_release_event.connect((e)=>{
			if(e.button!=3)
				return false;

			//stdout.printf("button:%u %f\n",e.button,e.y);
			Gtk.ListBoxRow r = this.friends.get_row_at_y((int)e.y);
			this.friends.select_row(r);
			popup1.set_id( r.name );
			popup1.popup_at_pointer(e);
			return true;
		});

		this.add_listbox_id(user1.id);
	}
	public void remove_friend(string fid){
		var grid = this.frd_boxes[fid];
		this.frd_boxes.unset(fid);
		this.frds1.unset(fid);
		if( false == rpc1.remove_friend(fid.to_int64()) ){
			Gtk.main_quit();
		}
		//hide row
		Gtk.ListBoxRow r = grid.get_parent() as Gtk.ListBoxRow;
		r.set_selectable(false);
		r.name="";
		//r.hide();
		this.friends.remove( r );
	}
	public void add_right_name_icon(string name,int16 sex){
		string iconp;
		if (sex==1)
			iconp = this.man_icon;
		else
			iconp = this.woman_icon;
        var pix1 = new Gdk.Pixbuf.from_file(iconp);
        var grid2 = new Gtk.Grid();
        var img2 = new Gtk.Image();
        img2.set_from_pixbuf(pix1);
        grid2.attach(img2,1,0);
        grid2.halign = Gtk.Align.END;
		var l2 = new Gtk.Label(name);
		l2.xalign = (float)1;
        grid2.attach(l2,0,0);
        grid2.set_column_spacing(5);
		this.msgs.add(grid2);
		grid2.show_all();
    }
    public void add_left_name_icon(string name,int16 sex){
		string iconp;
		if (sex==1)
			iconp = this.man_icon;
		else
			iconp = this.woman_icon;
        var grid1 = new Gtk.Grid();
        var pix1 = new Gdk.Pixbuf.from_file(iconp);
        var img1 = new Gtk.Image();
        img1.set_from_pixbuf(pix1);
        grid1.attach(img1,0,0);
		var l1 = new Gtk.Label(name);
		l1.xalign = (float)0;
        grid1.attach(l1,1,0);
        grid1.set_column_spacing(5);
		this.msgs.add(grid1);
		grid1.show_all();
    }
    public void add_image(string pathname){
        var p1 = new Gdk.Pixbuf.from_file(pathname);
        var image = new Gtk.Image();
        if(p1.width>300){
            var xs = (double)300/(double)p1.width;
            var h2 = (int)(p1.height*xs);
            var p2 = new Gdk.Pixbuf(Gdk.Colorspace.RGB,true,8,300,h2);
            p1.scale(p2, 0, 0, 300, h2, 0.0, 0.0, xs, xs,Gdk.InterpType.NEAREST);
            image.set_from_pixbuf(p2);
        }else{
            image.set_from_pixbuf(p1);
        }
		this.msgs.add(image);
		image.show();
    }
    public void add_text(string text,bool center=false ,bool markup=false){
        var lb = new Gtk.Label("");
        if(markup){
			lb.set_markup(text);
			var sc1 = lb.get_style_context();
			sc1.add_provider(this.link_css1,Gtk.STYLE_PROVIDER_PRIORITY_USER);
		} else
			lb.set_label(text);
		lb.wrap = true;
        lb.wrap_mode = Pango.WrapMode.CHAR;
        if(!center){
            lb.xalign = (float)0;
        }
        lb.width_request = 300;
        lb.max_width_chars = 15;
        var grid=new Gtk.Grid();
        var lb1 = new Gtk.Label("");
        lb1.width_request = 5;
        grid.attach(lb1,0,0);
        grid.attach(lb,1,0);
        var lb2 = new Gtk.Label("");
        lb2.width_request = 5;
        grid.attach(lb2,2,0);
        grid.halign = Gtk.Align.CENTER;
		this.msgs.add(grid);
		grid.show_all();
    }

	//callback in rpc msg
	public void rpc_callback(int8 typ,int64 from,string msg){
		//Msg　开头可以带着类型标记 JSON/TEXT
		print(@"ID: $(from) ,Msg: $(msg)\n");
		//from==0  "Offline id"
		if(from==0){
			if(msg.length<=8){
				return;
			}
			if(msg[0:8]=="Offline "){
				string off_id = msg[8:msg.length];
				//print("ID:%s : %s\n",off_id,msg);
				var grid = this.frd_boxes[off_id];
				var sc = grid.get_style_context();
				sc.add_provider(this.provider1,Gtk.STYLE_PROVIDER_PRIORITY_USER);
				if (sc.has_class("off")==false){
					sc.add_class("off");
					//move down
//					Gtk.ListBoxRow r = grid.get_parent() as Gtk.ListBoxRow;
//					r.set_selectable(false);
//					this.friends.remove(r);
//					this.friends.add(r);
//					r.set_selectable(true);
				}
				this.friends.invalidate_sort ();
				//show msg
				var tmp = this.msgs;
				this.msgs = this.boxes[off_id];
				this.add_text("[离线状态]",false);
				this.msgs = tmp;
				GLib.Idle.add(()=>{
					var adj1 = this.msgs.get_adjustment();
					adj1.value = adj1.upper;
					return false;
				});
				return;
			}
			print("Cmd:%i From:%"+int64.FORMAT+" Msg:%s\n",typ,from,msg);
			return;
		}
		//from>0
		string typ1 = msg[0:4];
		string msg1 = msg[4:msg.length];
		string fname="";
		int16 fsex=2;
		var u = this.frds1[from.to_string()];
		var display = this.boxes[from.to_string()];
		var bak_msgs = this.msgs;
		if( u!=null ){
			//print(@"has_key:$(u.name)\n");
			fname = u.name;
			fsex = u.sex;
			this.msgs = display;
		}else if (typ1 == "TEXT"){
			fname = @"ID:$(from)";
			bool ret = rpc1.offline_msg_with_id(from,msg1,(ux)=>{
				strangers1.prepend_row(ux);
			});
			if (ret==false)
				Gtk.main_quit();
			this.msgs = bak_msgs;
			return;
		}else if(typ1=="JSON"){
			fname = @"ID:$(from)";
		}

		switch(typ1){
		case "TEXT":
			//GLib.Idle.add(()=>{
			//this.msgs = display;
			this.add_right_name_icon(fname,fsex);
			this.add_text(msg1);
			//this.msgs = bak_msgs;
				//return false;
			//});
			msg_mark(from.to_string());
			break;
		case "JSON":
			var p2 = new Json.Parser();
			if(p2.load_from_data(msg1)==false){
				break;
			}
			var node2 = p2.get_root();
			if (node2==null){
				break;
			}
			var obj2 = node2.get_object();
			string name1 = obj2.get_string_member("Name");
			string mime1 = obj2.get_string_member("Mime");
			string display_text = @"点击打开文件：<a href='file://$(name1)'>$(GLib.Path.get_basename(name1))</a>  <a href='file://$(GLib.Path.get_dirname(name1))'>打开目录</a>";
			if(mime1[0:5]=="image"){
				//GLib.Idle.add(()=>{
				//this.msgs = display;
				this.add_right_name_icon(fname,fsex);
				this.add_image(name1);
				this.add_text(display_text,true,true);
				//this.msgs = bak_msgs;
					//return false;
				//});
			}else{
				//GLib.Idle.add(()=>{
				//this.msgs = display;
				this.add_right_name_icon(fname,fsex);
				this.add_text(display_text,true,true);
				//this.msgs = bak_msgs;
					//return false;
				//});
			}
			var rm_btn = new Gtk.Button.with_label(@"删除可疑文件：$(GLib.Path.get_basename(name1))");
			this.msgs.add(rm_btn);
			rm_btn.clicked.connect(()=>{
				GLib.FileUtils.remove(name1);
				print(@"remove $(name1)\n");
			});
			msg_mark(from.to_string());
			this.msgs.show_all();
			break;
		case "LOGI":
			if( u==null )
				break;
			Gtk.Grid grid = this.frd_boxes[from.to_string()];
			var sc3 = grid.get_style_context();
			sc3.remove_provider(this.provider1);
			sc3.remove_class("off");
			this.friends.invalidate_sort ();
			break;
		}
		GLib.Idle.add(()=>{
			var adj1 = this.msgs.get_adjustment();
			adj1.value = adj1.upper;
			return false;
		});
		this.msgs = bak_msgs;
	}
	public void msg_mark(string uid){
		Gtk.ListBoxRow r = this.frd_boxes[uid].get_parent() as Gtk.ListBoxRow;
		if(r.is_selected())
			return;
		Gtk.Grid grid = this.frd_boxes[uid];
		var sc3 = grid.get_style_context();
		sc3.add_provider(this.mark1,Gtk.STYLE_PROVIDER_PRIORITY_USER);
		sc3.add_class("mark");
		grid.show_all();
		print(@"mark: $(uid)\n");
	}
}

public class AppWin:Gtk.Window{
	public AppWin(){
		// Sets the title of the Window:
		this.title = "人人公众号";

		// Center window at startup:
		this.window_position = Gtk.WindowPosition.CENTER;

		// Sets the default size of a window:
		this.set_default_size(640,480);
		// Whether the titlebar should be hidden during maximization.
		this.hide_titlebar_when_maximized = true;

        this.set_resizable(false);
        this.set_icon_from_file("tank.png");

		// Method called on pressing [X]
		this.destroy.connect (() => {
			// Print "Bye!" to our console:
			print ("Bye!\n");
			grid1.release_resource();
			// Terminate the mainloop: (main returns 0)
			Gtk.main_quit ();
		});
	}
}

public class LoginDialog :GLib.Object{
	public Gtk.Entry name;
	public Gtk.Entry passwd;
	public Gtk.Dialog dlg1;
	//public Thread<int> thread;
	public LoginDialog(){
		this.dlg1 = new Gtk.Dialog.with_buttons("登录",app,Gtk.DialogFlags.MODAL);
		var grid = new Gtk.Grid();
		grid.attach(new Gtk.Label("输入登录信息"),0,0,2,1);
		grid.attach(new Gtk.Label("用户："),0,1,1,1);
		grid.attach(new Gtk.Label("密码："),0,2,1,1);
		this.name = new Gtk.Entry();
		grid.attach(this.name,1,1,1,1);
		this.passwd = new Gtk.Entry();
		this.passwd.set_visibility(false);
		grid.attach(this.passwd,1,2,1,1);
		var content = this.dlg1.get_content_area () as Gtk.Box;
		content.pack_start(grid);
		content.show_all();
		this.dlg1.add_button("登录",2);
		this.dlg1.add_button("注册",4);
		this.dlg1.add_button("取消",3);

		this.dlg1.response.connect((rid)=>{
			if (rid==2){
				//stdout.printf("next %d\n%s\n%s\n",rid,this.name.text,this.passwd.text);
				UserData u;
				var res = rpc1.login(this.name.text,this.passwd.text,out u);
				if (res>0){
					stdout.printf("login ok\n");
					grid1.uid = res;
					grid1.uname = u.name;
					grid1.usex = u.sex;
					grid1.uage = u.age;
					grid1.udesc = u.desc;
					grid1.user_btn.label = u.name;
				}else{
					this.dlg1.title = "用户／密码错误。";
					stdout.printf("login fail\n");
					return;
				}
				if(rpc1.get_friends_async()==false){
					print("RPC error");
					Gtk.main_quit();
				}
				app.show_all();
				this.dlg1.hide();
			}else if(rid==4){
				this.dlg1.hide();
				adduser1 = new AddUserDialog();
				adduser1.show();
			}else{
				Gtk.main_quit();
			}
		});
	}
	public int run(){
		return this.dlg1.run();
	}
	public void hide(){
		this.dlg1.hide();
	}
}
static uint16 server_port=7890;
static uint16 proxy_port;
public static int main(string[] args){
	if (!Thread.supported()) {
		stderr.printf("Cannot run without threads.\n");
		return 1;
	}
	if(args.length==2){
		server_port = (uint16)args[1].to_int64();
	}
	//proxy_port = server_port + 2000;
	rpc1 = new RpcClient();
	if (rpc1.connect("localhost",server_port)==false){
		return -1;
	}
	rpc1.c.notification.connect((s,m,p)=>{
		stdout.printf("notify: %s\n",m);
		if (m!="msg")
			return;
		try{
			var typ = (int8) p.lookup_value("T",null).get_int64();
			var from = p.lookup_value("From",null).get_int64();
			var msg = p.lookup_value("Msg",null).get_string();
			grid1.rpc_callback(typ,from,to_local(msg));
		}catch(Error e){
			stdout.printf ("Error: %s\n", e.message);
		}
	});

	Gtk.init(ref args);
	app = new AppWin();
	grid1 = new MyGrid();
	app.add(grid1.mygrid);

	login1 = new LoginDialog();
	login1.dlg1.show_all();

	popup1 = new MyFriendMenu();

	Gtk.main ();
	rpc1.quit();
	rpc1.c.close();
	return 0;
}
