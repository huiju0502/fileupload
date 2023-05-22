<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oreilly.servlet.MultipartRequest" %>
<%@ page import="com.oreilly.servlet.multipart.DefaultFileRenamePolicy" %>
<%@ page import="vo.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.sql.*" %>
<%

	// upload된 파일의 위치 
	String dir = request.getServletContext().getRealPath("/upload");
	int max = 10 * 1024 * 1024;
	MultipartRequest mRequest = new MultipartRequest(request, dir, max, "utf-8", new DefaultFileRenamePolicy());

	// 요청값
	int boardNo = Integer.parseInt(mRequest.getParameter("boardNo"));
	String saveFilename = mRequest.getParameter("saveFilename");

	// 1) 업로드된 파일 삭제
	File f = new File(dir + "/" + saveFilename);
	if(f.exists()) {
		f.delete();
		System.out.println(saveFilename + "파일삭제");
	}
	
	// 2) board테이블에서 db 삭제
	/*
	DELETE
	FROM board
	WHERE board_no = ?		
	*/
	Class.forName("org.mariadb.jdbc.Driver");
	Connection conn = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/fileupload","root","2152");
	String removeBoardSql = "DELETE FROM board WHERE board_no = ?";
	PreparedStatement removeBoardStmt = conn.prepareStatement(removeBoardSql);
	removeBoardStmt.setInt(1,boardNo);
	int boardFileRow = removeBoardStmt.executeUpdate();
	
	response.sendRedirect(request.getContextPath() + "/boardList.jsp");
%>