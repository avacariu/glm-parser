# distutils: language = c++
from libcpp.utility cimport pair
from libcpp.queue cimport queue
from libcpp.vector cimport vector
from libcpp.algorithm cimport sort as stdsort
from libcpp.algorithm cimport push_heap, pop_heap
from libcpp.list cimport list
from libcpp cimport bool
from libc.stdlib cimport malloc, calloc, free

cdef struct EisnerNode:
    float score
    int mid_index
    
#TODO try size_t
cdef struct EdgeRecoverNode:
    int s
    int t
    int orientation
    int shape

cdef bool max_heap_comp(EisnerNode a, EisnerNode b):
    return a.score < b.score
    
cdef bool sort_comp(EisnerNode a, EisnerNode b):
    return a.score > b.score

cdef cppclass EisnerHeap:
    vector[EisnerNode] data
    int maxSize
    EisnerHeap(int size):
        maxSize = size

    void push_back(EisnerNode node):
        data.push_back(node)
        push_heap(data.begin(), data.end(), &max_heap_comp)

    void pop_front():
        pop_heap(data.begin(), data.end(), &max_heap_comp)
        data.pop_back()

    void push(EisnerNode node):
        push_back(node)
        if data.size() > maxSize:
            pop_front()

    void sort():
        stdsort(data.begin(), data.end(), &sort_comp)

    EisnerNode front():
        return data.front()

ctypedef EisnerHeap* P_EisnerHeap
ctypedef EisnerHeap** PP_EisnerHeap   

cdef class EisnerParser:
    cdef PP_EisnerHeap ***e
    cdef list[pair[int, int]] edge_list
    cdef int n
    cdef int tt
    def __cinit__(self):
        pass
    
    def init_eisner_matrix(self, max_size):
        self.e = <PP_EisnerHeap***>malloc(self.n*sizeof(PP_EisnerHeap**))
        cdef int i, j, k, l
        for i in range(self.n):
            self.e[i] = <P_EisnerHeap***>calloc(self.n,sizeof(P_EisnerHeap**))
            for j in range(self.n):
                self.e[i][j] = <P_EisnerHeap**>calloc(2,sizeof(P_EisnerHeap*))
                for k in range(2):
                    self.e[i][j][k] = <P_EisnerHeap*>calloc(2,sizeof(P_EisnerHeap))
                    for l in range(2):
                        self.e[i][j][k][l] = new EisnerHeap(max_size)
                        self.e[i][j][k][l].push(EisnerNode(0,0))
                        
        return

    def delete_eisner_matrix(self):
        cdef int i, j, k
        for i in range(self.n):
            for j in range(self.n):
                for k in range(2):
                    for l in range(2):
                        free(self.e[i][j][k][l])
                    free(self.e[i][j][k])
                free(self.e[i][j])
            free(self.e[i])

    
    def combine_triangle(self, head, modifier, arc_weight, sent, cube_prunning):
        # s < t strictly
        if head == modifier:
            print "invalid head and modifier for combine triangle!!!"
            
        cdef int s, t, q
        cdef bool direction
        if head < modifier:
            s = head
            t = modifier
            direction = 1
        else:
            s = modifier
            t = head
            direction = 0
            
        cdef float edge_score = arc_weight(sent.get_local_vector(head, modifier))
        cdef EisnerNode node

        for q from s < q < t by 1:
            if cube_prunning == 0:
                edge_score = arc_weight(sent.get_local_vector(head, modifier, None, 0))
                node.score = \
                    self.e[s][q][1][0].front().score + self.e[q+1][t][0][0].front().score + edge_score
                node.mid_index = q
                self.e[s][t][direction][1].push(node)

        self.e[s][t][direction][1].sort()
    
    cdef combine_left(self, int s, int t, bool cube_prunning):        
        # s < t strictly
        if s >= t:
            print "invalid head and modifier for combine left!!!"
        
        cdef EisnerNode node

        cdef int q
        for q from s < q < t by 1:
            if cube_prunning == 0:
                node.score = self.e[s][q][0][0].front().score + self.e[q][t][0][1].front().score
                node.mid_index = q
                self.e[s][t][0][0].push(node)
        
        self.e[s][t][0][0].sort()
       
    cdef combine_right(self, int s, int t, bool cube_prunning):
        # s < t strictly
        if s >= t:
            print "invalid head and modifier for combine right!!!"
        
        cdef EisnerNode node
        cdef int q
        for q from s < q <= t by 1:
            node.score = self.e[s][q][1][1].front().score + self.e[q][t][1][0].front().score
            node.mid_index = q
            self.e[s][t][1][0].push(node)
    
        self.e[s][t][1][0].sort()

    cdef EdgeRecoverNode new_edge_recover_node(self, int s, int t, int orien, int shape):
        cdef EdgeRecoverNode new_node
        new_node.s = s
        new_node.t = t
        new_node.orientation = orien
        new_node.shape = shape

        return new_node
    
    cdef split_right_triangle(self, EdgeRecoverNode node):
        """
        right triangle: e[s][t][1][0]
        """
        cdef EdgeRecoverNode node_left, node_right
        
        cdef int q = self.e[node.s][node.t][1][0].front().mid_index
        
        node_left = self.new_edge_recover_node(node.s, q, 1, 1)
        node_right = self.new_edge_recover_node(q, node.t, 1, 0)

        return node_left, node_right
        
    cdef split_left_triangle(self, EdgeRecoverNode node):
        """
        left triangle: e[s][t][0][0]
        """
        cdef EdgeRecoverNode node_left, node_right
        
        cdef int q = self.e[node.s][node.t][0][0].front().mid_index
        
        node_left = self.new_edge_recover_node(node.s, q, 0, 0)
        node_right = self.new_edge_recover_node(q, node.t, 0, 1)

        return node_left, node_right

    cdef split_right_trapezoid(self, EdgeRecoverNode node):
        """
        right trapezoid: e[s][t][1][1]
        """
        cdef pair[int, int] edge
        edge.first = node.s
        edge.second = node.t
        self.edge_list.push_back(edge)
        
        cdef EdgeRecoverNode node_left, node_right

        cdef int q = self.e[node.s][node.t][1][1].front().mid_index
        node_left = self.new_edge_recover_node(node.s, q, 1, 0)
        node_right = self.new_edge_recover_node(q+1, node.t, 0, 0)
        
        return node_left, node_right

    cdef split_left_trapezoid(self, EdgeRecoverNode node):
        """
        left trapezoid: e[s][t][0][1]
        """
        cdef pair[int, int] edge
        edge.first = node.t
        edge.second = node.s
        self.edge_list.push_back(edge)
        
        cdef EdgeRecoverNode node_left, node_right

        cdef int q = self.e[node.s][node.t][0][1].front().mid_index
        node_left = self.new_edge_recover_node(node.s, q, 1, 0)
        node_right = self.new_edge_recover_node(q+1, node.t, 0, 0)

        return node_left, node_right

    
    cdef get_edge_list(self):
        
        cdef EdgeRecoverNode node, node_left, node_right
        cdef queue[EdgeRecoverNode] node_queue

        if not self.edge_list.empty():
            self.edge_list.clear()
        
        node_queue.push(self.new_edge_recover_node(0, self.n-1, 1, 0))
        while not node_queue.empty():
            push = False
            node = node_queue.front()
            node_queue.pop()
            
            if node.orientation == 1 and node.shape == 0:
                node_left, node_right = self.split_right_triangle(node)
                push = True
            if node.orientation == 0 and node.shape == 0:
                node_left, node_right = self.split_left_triangle(node)
                push = True
            if node.orientation == 1 and node.shape == 1:
                node_left, node_right = self.split_right_trapezoid(node)
                push = True
            if node.orientation == 0 and node.shape == 1:
                node_left, node_right = self.split_left_trapezoid(node)
                push = True
                
            if push:
                if node_left.s != node_left.t:
                    node_queue.push(node_left)
                if node_right.s != node_right.t:
                    node_queue.push(node_right)
        return
    
    def parse(self, sent, arc_weight):	

        self.n = len(sent.word_list)
        self.init_eisner_matrix()

        cdef int m, s, t, q
        
        #TODO: try for m in range(1,self.n)
        for m from 1 <= m < self.n by 1: 
            for s from 0 <= s < self.n by 1:
                t = s + m
                if t >= self.n:
                    break
                
                self.combine_triangle(t, s, arc_weight, sent, 0)
                self.combine_triangle(s, t, arc_weight, sent, 0)
                self.combine_left(s, t, 0)
                self.combine_right(s, t, 0)
       
        self.get_edge_list()       
        self.delete_eisner_matrix()

        return self.edge_list
        
